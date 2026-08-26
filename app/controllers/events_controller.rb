class EventsController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:index, :ingest, :ingest_all]

  # Require authentication for voting
  before_action :authenticate_user!, only: [ :vote ]

  def index
    @events = Event.published.upcoming.available
    # Will implement pagination later
    # @events = @events.page(params[:page]).per(20)

    @last_ingestion = Rails.cache.read("last_event_ingestion")
    if user_signed_in?
      @user_votes = current_user.votes.where(event: @events).index_by(&:event_id)
    end
  end

  def ingest
    EventIngestionJob.perform_later(limit: 10)

    flash[:notice] = "Event ingestion started in background. It may take a few moments."
    redirect_to events_path
  end

  def ingest_all
    EventIngestionJob.perform_later

    flash[:notice] = "Full event ingestion started in background. This may take several minutes."
    redirect_to events_path
  end

  def sync_status
    status = Rails.cache.read("last_event_ingestion")

    if status
      render json: {
        success: true,
        last_run: status[:timestamp],
        results: status[:result]
      }
    else
      render json: { success: false, message: "No ingestion has been run yet" }
    end
  end

  def vote
    unless user_signed_in?
      render json: {
        success: false,
        error: "login_required",
        message: "Please sign in to vote"
      }, status: :unauthorized
      return
    end

    begin
      event = Event.find(params[:id])
      vote_type = params[:vote_type]

      unless %w[upvote downvote].include?(vote_type)
        render json: { success: false, error: "Invalid vote type" }, status: :unprocessable_entity
        return
      end

      existing = current_user.votes.find_by(event: event)
      action = nil

      ActiveRecord::Base.transaction do
        if existing.nil?
          Vote.create!(user: current_user, event: event, vote_type: vote_type)
          action = "created"
        elsif existing.vote_type == vote_type
          existing.destroy!
          action = "removed"
        else
          existing.update!(vote_type: vote_type)
          action = "changed"
        end

        # FIX: Force accurate counts for BOTH upvotes and downvotes
        event.update_votes_count
        event.reload # Reload to get the freshest data from the DB
      end
      render json: {
        success: true,
        upvotes: event.upvotes_count,
        downvotes: event.downvotes_count,
        total_score: event.total_score,
        user_vote: event.user_vote(current_user)&.vote_type,
        action: action,
        message: vote_message(action, vote_type)
      }
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def vote_message(action, vote_type)
    case action
    when "created" then "#{vote_type} added!"
    when "removed" then "#{vote_type} removed!"
    when "changed" then "Vote changed to #{vote_type}!"
    else "Vote updated!"
    end
  end
end

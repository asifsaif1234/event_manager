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
    event = Event.find(params[:id])
    result = VoteRecorder.new(user: current_user, event: event, vote_type: params[:vote_type]).call

    render json: {
      success: true,
      upvotes: result.event.upvotes_count,
      downvotes: result.event.downvotes_count,
      total_score: result.event.total_score,
      user_vote: result.user_vote,
      action: result.action,
      message: vote_message(result.action, params[:vote_type])
    }
  rescue VoteRecorder::InvalidVoteType => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "Event not found" }, status: :not_found
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
end

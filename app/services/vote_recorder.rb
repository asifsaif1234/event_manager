# app/services/vote_recorder.rb
class VoteRecorder
  class InvalidVoteType < StandardError; end

  VALID_TYPES = %w[upvote downvote].freeze

  Result = Struct.new(:action, :event, :user_vote, keyword_init: true)

  def initialize(user:, event:, vote_type:)
    @user = user
    @event = event
    @vote_type = vote_type
    @retried   = false
  end

  def call
    raise ArgumentError, "User required" if user.nil?
    raise InvalidVoteType, "Invalid vote type" unless VALID_TYPES.include?(vote_type)

    action = nil

    ActiveRecord::Base.transaction do
      existing = user.votes.lock.find_by(event: event)

      if existing.nil?
        Vote.create!(user: user, event: event, vote_type: vote_type)
        action = "created"
      elsif existing.vote_type == vote_type
        existing.destroy!
        action = "removed"
      else
        existing.update!(vote_type: vote_type)
        action = "changed"
      end

      event.update_votes_count
      event.reload
    end

    Result.new(action: action, event: event, user_vote: event.user_vote(user)&.vote_type)
  rescue ActiveRecord::RecordNotUnique
    raise if @retried

    @retried = true
    retry
  end

  private

  attr_reader :user, :event, :vote_type
end

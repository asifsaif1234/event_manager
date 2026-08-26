class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :vote_type, presence: true, inclusion: { in: %w[upvote downvote] }
  validates :user_id, uniqueness: { scope: :event_id, message: "has already voted for this event" }

  scope :upvotes, -> { where(vote_type: "upvote") }
  scope :downvotes, -> { where(vote_type: "downvote") }

  after_create :update_event_counts, :publish_vote_event
  after_destroy :update_event_counts, :publish_vote_removed_event

   private

  def publish_vote_event
    # Use reload to ensure associations are loaded
    user = self.user
    event = self.event

    event_class = vote_type == "upvote" ? ::EventUpvoted : ::EventDownvoted

    Rails.configuration.event_store.publish(
      event_class.new(
        data: {
          vote_id: id,
          user_id: user_id,
          clerk_user_id: user&.clerk_id,
          user_email: user&.email,
          event_id: event_id,
          event_title: event&.title,
          vote_type: vote_type,
          timestamp: Time.current.iso8601
        }
      ),
      stream_name: "Vote$#{id}"
    )
  rescue => e
    Rails.logger.error "Failed to publish vote event: #{e.message}"
  end

  def publish_vote_removed_event
    user = self.user
    event = self.event

    Rails.configuration.event_store.publish(
      ::EventVoteRemoved.new(
        data: {
          vote_id: id,
          user_id: user_id,
          clerk_user_id: user&.clerk_id,
          user_email: user&.email,
          event_id: event_id,
          event_title: event&.title,
          previous_vote_type: vote_type,
          timestamp: Time.current.iso8601
        }
      ),
      stream_name: "Vote$#{id}"
    )
  rescue => e
    Rails.logger.error "Failed to publish vote removed event: #{e.message}"
  end

  def update_event_counts
    event.update_votes_count
  end
end

class User < ApplicationRecord
  has_many :votes, dependent: :destroy
  has_many :events, through: :votes

  validates :clerk_id, presence: true, uniqueness: true
  # Romove Regex and case sesitive because clerk handle this is just aad in DB
  validates :email, presence: true

  def display_name
    first_name.presence || email.split("@").first
  end

  def self.find_or_create_from_clerk(clerk_user)
    # Extract email from Clerk user
    email = clerk_user.email_addresses&.first&.email_address
    user = find_or_initialize_by(clerk_id: clerk_user.id)

    user.assign_attributes(
      email: email,
      first_name: clerk_user.first_name,
      last_name: clerk_user.last_name,
      avatar_url: clerk_user.image_url,
      last_synced_at: Time.current
    )

    user.save! if user.changed?
    user
  rescue => e
    Rails.logger.error "Error syncing user: #{e.message}"
    nil
  end
end

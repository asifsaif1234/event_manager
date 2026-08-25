class User < ApplicationRecord
  has_many :votes, dependent: :destroy
  has_many :events, through: :votes

  validates :clerk_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active_users, -> { where(status: :active) }
  scope :recently_signed_in, -> { where("last_signed_in_at > ?", 7.days.ago) }

  def display_name
    name.presence || email.split("@").first
  end

  def active?
    status == "active"
  end

  def voted_for?(event)
    votes.exists?(event: event)
  end

  def vote_for(event)
    votes.find_by(event: event)
  end

  def record_sign_in!
    update_column(:last_signed_in_at, Time.current)
  end

  def self.find_or_create_from_clerk(clerk_user)
    # Extract email from Clerk user
    email = clerk_user.email_addresses&.first&.email_address

    # Find or create user
    user = find_or_initialize_by(clerk_id: clerk_user.id)

    user.assign_attributes(
      email: email,
      first_name: clerk_user.first_name,
      last_name: clerk_user.last_name,
      avatar_url: clerk_user.image_url
    )

    user.save! if user.changed?
    user
  rescue => e
    Rails.logger.error "Error syncing user: #{e.message}"
    nil
  end

  def self.sync_from_clerk(clerk_user)
    return nil unless clerk_user.present?

    primary_email = clerk_user["email_addresses"]&.find { |e| e["id"] == clerk_user["primary_email_address_id"] }
    email = primary_email&.dig("email_address") || clerk_user["email_addresses"]&.first&.dig("email_address")

    user = find_or_initialize_by(clerk_id: clerk_user["id"])

    user.assign_attributes(
      email: email,
      first_name: clerk_user["first_name"],
      last_name: clerk_user["last_name"],
      name: clerk_user["name"] || [ clerk_user["first_name"], clerk_user["last_name"] ].compact.join(" "),
      avatar_url: clerk_user["image_url"],
      public_metadata: clerk_user["public_metadata"] || {},
      private_metadata: clerk_user["private_metadata"] || {},
      status: :active,
      last_synced_at: Time.current
    )

    user.save! if user.changed?
    user
  rescue => e
    Rails.logger.error "Failed to sync user: #{e.message}"
    nil
  end

  def self.sync_from_clerk_webhook(clerk_user)
    return nil unless clerk_user.present?

    user = find_or_initialize_by(clerk_id: clerk_user["id"])

    primary_email = clerk_user["email_addresses"]&.find { |e| e["id"] == clerk_user["primary_email_address_id"] }
    email = primary_email&.dig("email_address") || clerk_user["email_addresses"]&.first&.dig("email_address")

    user.assign_attributes(
      email: email,
      first_name: clerk_user["first_name"],
      last_name: clerk_user["last_name"],
      name: clerk_user["name"] || [ clerk_user["first_name"], clerk_user["last_name"] ].compact.join(" "),
      avatar_url: clerk_user["image_url"],
      public_metadata: clerk_user["public_metadata"] || {},
      private_metadata: clerk_user["private_metadata"] || {},
      status: clerk_user["deleted"] ? :inactive : :active,
      last_synced_at: Time.current
    )

    user.save! if user.changed?
    user
  rescue => e
    Rails.logger.error "Failed to sync user from webhook: #{e.message}"
    nil
  end
end

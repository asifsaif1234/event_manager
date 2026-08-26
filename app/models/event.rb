class Event < ApplicationRecord
  VALID_STATES = %w[published draft scheduled cancelled].freeze

  has_many :votes, dependent: :destroy
  has_many :users, through: :votes

  validates :event_id, presence: true, uniqueness: true
  validates :title, presence: true, length: { minimum: 2, maximum: 255 }
  validates :start_date, presence: true
  validates :state, presence: true, inclusion: { in: VALID_STATES }
  validates :description, length: { maximum: 10000 }, allow_blank: true

  validate :end_date_after_start_date, if: -> { end_date.present? && start_date.present? }
  validate :valid_image_url, if: -> { image_link.present? }

  before_save :sanitize_data
  before_save :ensure_json_fields

  scope :published, -> { where(state: "published") }
  scope :upcoming, -> { where("start_date > ?", Time.current).order(:start_date) }
  scope :available, -> { where(availability: true) }

  def formatted_price
    return "Free" if price_amount_in_cents.blank? || price_amount_in_cents.zero?
    "#{price_amount_in_cents.to_f / 100} #{price_currency || 'DKK'}"
  end

  def organiser_name
    organiser_data["name"] if organiser_data.present?
  end

  def location_name
    location_data["location_name"] if location_data.present?
  end

  def category
    categorization_data["category_localized"] if categorization_data.present?
  end

  def full_address
    return nil if location_data.blank?
    [
      location_data["address_line"],
      location_data["address_line_2"],
      location_data["postal_code"],
      location_data["city"],
      location_data["country"]
    ].compact.reject(&:blank?).join(", ")
  end

   def update_votes_count
    update_columns(
      upvotes_count: votes.upvotes.count,
      downvotes_count: votes.downvotes.count
    )
  end

  def total_score
    upvotes_count - downvotes_count
  end

  def user_vote(user)
    votes.find_by(user: user) if user
  end

  def user_voted?(user)
    user_vote(user).present?
  end

  private

  def end_date_after_start_date
    if end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def valid_image_url
    unless image_link =~ /\Ahttps?:\/\/.+/i
      errors.add(:image_link, "must be a valid URL")
    end
  rescue URI::InvalidURIError
    errors.add(:image_link, "has invalid format")
  end

  def sanitize_data
    self.title = title.strip if title.present?
    self.description = description.strip if description.present?
    self.image_link = image_link.strip if image_link.present?
  end

  def ensure_json_fields
    self.organiser_data = {} if organiser_data.blank?
    self.location_data = {} if location_data.blank?
    self.categorization_data = {} if categorization_data.blank?
    self.organization_data = {} if organization_data.blank?
  end
end

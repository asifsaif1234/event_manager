require 'rails_helper'

RSpec.describe Event, type: :model do
  # --- Associations ---
  describe "associations" do
    it { should have_many(:votes).dependent(:destroy) }
    it { should have_many(:users).through(:votes) }
  end

  # --- Validations ---
  describe "validations" do
    subject { build(:event) }

    it { should validate_presence_of(:event_id) }
    it { should validate_uniqueness_of(:event_id) }
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(2).is_at_most(255) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:state) }
    it { should validate_inclusion_of(:state).in_array(%w[published draft scheduled cancelled]) }
    it { should validate_length_of(:description).is_at_most(10000).allow_blank }

    # Custom validation: end_date after start_date
    describe "end_date_after_start_date" do
      it "is valid when end_date is after start_date" do
        event = build(:event, start_date: Date.today, end_date: Date.tomorrow)
        expect(event).to be_valid
      end

      it "is invalid when end_date is before start_date" do
        event = build(:event, start_date: Date.today, end_date: Date.yesterday)
        expect(event).to_not be_valid
        expect(event.errors[:end_date]).to include("must be after start date")
      end

      it "is valid when end_date is nil" do
        event = build(:event, end_date: nil)
        expect(event).to be_valid
      end
    end

    # Custom validation: image URL
    describe "valid_image_url" do
      it "is valid with http/https URL" do
        event = build(:event, image_link: "https://example.com/image.jpg")
        expect(event).to be_valid
      end

      it "is invalid with invalid URL" do
        event = build(:event, image_link: "ftp://invalid")
        expect(event).to_not be_valid
        expect(event.errors[:image_link]).to include("must be a valid URL")
      end

      it "is valid when image_link is blank" do
        event = build(:event, image_link: nil)
        expect(event).to be_valid
      end
    end
  end

  # --- Scopes ---
  describe "scopes" do
    let!(:published_future_event) { create(:event, state: "published", start_date: Date.tomorrow) }
    let!(:draft_future_event) { create(:event, state: "draft", start_date: Date.tomorrow) }
    let!(:published_past_event) { create(:event, state: "published", start_date: Date.yesterday) }
    let!(:published_unavailable_event) { create(:event, state: "published", start_date: Date.tomorrow, availability: false) }

    describe ".published" do
      it "returns only published events" do
        expect(Event.published).to include(published_future_event, published_past_event)
        expect(Event.published).to_not include(draft_future_event)
      end
    end

    describe ".upcoming" do
      it "returns only events with start_date in the future" do
        expect(Event.upcoming).to include(published_future_event, draft_future_event, published_unavailable_event)
        expect(Event.upcoming).to_not include(published_past_event)
      end
    end

    describe ".available" do
      it "returns only available events" do
        expect(Event.available).to include(published_future_event, draft_future_event)
        expect(Event.available).to_not include(published_unavailable_event)
      end
    end
  end

  # --- Instance Methods ---
  describe "instance methods" do
    let(:event) { create(:event) }

    describe "#formatted_price" do
      it "returns 'Free' when price is nil" do
        event = build(:event, price_amount_in_cents: nil)
        expect(event.formatted_price).to eq("Free")
      end

      it "returns 'Free' when price is zero" do
        event = build(:event, price_amount_in_cents: 0)
        expect(event.formatted_price).to eq("Free")
      end

      it "formats price with currency" do
        event = build(:event, price_amount_in_cents: 1500, price_currency: "DKK")
        expect(event.formatted_price).to eq("15.0 DKK")
      end
    end

    describe "#organiser_name" do
      it "returns the organiser name if present" do
        event = build(:event, organiser_data: { "name" => "Test Organiser" })
        expect(event.organiser_name).to eq("Test Organiser")
      end

      it "returns nil if organiser_data is empty" do
        event = build(:event, organiser_data: {})
        expect(event.organiser_name).to be_nil
      end
    end

    describe "#location_name" do
      it "returns the location name if present" do
        event = build(:event, location_data: { "location_name" => "Copenhagen" })
        expect(event.location_name).to eq("Copenhagen")
      end

      it "returns nil if location_data is empty" do
        event = build(:event, location_data: {})
        expect(event.location_name).to be_nil
      end
    end

    describe "#category" do
      it "returns the category if present" do
        event = build(:event, categorization_data: { "category_localized" => "Music" })
        expect(event.category).to eq("Music")
      end
    end

    describe "#full_address" do
      it "returns nil if location_data is blank" do
        event = build(:event, location_data: nil)
        expect(event.full_address).to be_nil
      end

      it "joins address components" do
        event = build(:event, location_data: { "address_line" => "123 St", "city" => "Copenhagen", "country" => "Denmark" })
        expect(event.full_address).to eq("123 St, Copenhagen, Denmark")
      end
    end

    describe "#update_votes_count" do
      it "updates the counters based on actual votes" do
        event = create(:event)
        user1 = create(:user)
        user2 = create(:user)

        create(:vote, user: user1, event: event, vote_type: "upvote")
        create(:vote, user: user2, event: event, vote_type: "downvote")

        event.reload
        expect(event.upvotes_count).to eq(1)
        expect(event.downvotes_count).to eq(1)
      end
    end

    describe "#total_score" do
      it "calculates the total score" do
        event = build(:event, upvotes_count: 5, downvotes_count: 3)
        expect(event.total_score).to eq(2)
      end
    end

    describe "#user_vote" do
      it "returns the vote for a given user" do
        user = create(:user)
        event = create(:event)
        vote = create(:vote, user: user, event: event)

        expect(event.user_vote(user)).to eq(vote)
      end

      it "returns nil if user is nil" do
        event = create(:event)
        expect(event.user_vote(nil)).to be_nil
      end
    end

    describe "#user_voted?" do
      it "returns true if user has voted" do
        user = create(:user)
        event = create(:event)
        create(:vote, user: user, event: event)

        expect(event.user_voted?(user)).to be true
      end

      it "returns false if user has not voted" do
        user = create(:user)
        event = create(:event)

        expect(event.user_voted?(user)).to be false
      end
    end
  end

  # --- Callbacks ---
  describe "callbacks" do
    describe "#sanitize_data" do
      it "trims title and description before save" do
        event = build(:event, title: "  Hello World  ", description: "  Test Desc  ")
        event.save
        expect(event.reload.title).to eq("Hello World")
        expect(event.reload.description).to eq("Test Desc")
      end
    end

    describe "#ensure_json_fields" do
      it "sets default empty hashes for blank JSON fields" do
        event = build(:event, organiser_data: nil, location_data: nil, categorization_data: nil, organization_data: nil)
        event.save
        expect(event.reload.organiser_data).to eq({})
        expect(event.reload.location_data).to eq({})
        expect(event.reload.categorization_data).to eq({})
        expect(event.reload.organization_data).to eq({})
      end
    end
  end
end

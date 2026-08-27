require 'rails_helper'

RSpec.describe Vote, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:event) }
  end

  describe "validations" do
    subject { build(:vote) }

    it { should validate_presence_of(:vote_type) }
    it { should validate_inclusion_of(:vote_type).in_array(%w[upvote downvote]) }

    it "validates uniqueness of user scoped to event" do
      user = create(:user)
      event = create(:event)
      create(:vote, user: user, event: event, vote_type: "upvote")

      duplicate_vote = build(:vote, user: user, event: event, vote_type: "downvote")

      expect(duplicate_vote).to_not be_valid
      expect(duplicate_vote.errors[:user_id]).to include("has already voted for this event")
    end
  end

  describe "scopes" do
    let!(:upvote) { create(:vote, vote_type: "upvote") }
    let!(:downvote) { create(:vote, vote_type: "downvote") }

    describe ".upvotes" do
      it "returns only upvotes" do
        expect(Vote.upvotes).to include(upvote)
        expect(Vote.upvotes).to_not include(downvote)
      end
    end

    describe ".downvotes" do
      it "returns only downvotes" do
        expect(Vote.downvotes).to include(downvote)
        expect(Vote.downvotes).to_not include(upvote)
      end
    end
  end

  describe "callbacks" do
    describe "after_create :publish_vote_event" do
      it "publishes an EventUpvoted event when creating an upvote" do
        # Mock the event store to succeed
        event_store = instance_double("RailsEventStore::Client")
        allow(Rails.configuration).to receive(:event_store).and_return(event_store)
        allow(event_store).to receive(:publish)

        user = create(:user)
        event = create(:event)
        vote = create(:vote, user: user, event: event, vote_type: "upvote")

        expect(event_store).to have_received(:publish).with(
          an_instance_of(EventUpvoted),
          stream_name: "Vote$#{vote.id}"
        ).once
      end

      it "publishes an EventDownvoted event when creating a downvote" do
        event_store = instance_double("RailsEventStore::Client")
        allow(Rails.configuration).to receive(:event_store).and_return(event_store)
        allow(event_store).to receive(:publish)

        user = create(:user)
        event = create(:event)
        vote = create(:vote, user: user, event: event, vote_type: "downvote")

        expect(event_store).to have_received(:publish).with(
          an_instance_of(EventDownvoted),
          stream_name: "Vote$#{vote.id}"
        ).once
      end

      it "logs an error if publishing fails" do
        event_store = instance_double("RailsEventStore::Client")
        allow(Rails.configuration).to receive(:event_store).and_return(event_store)
        allow(event_store).to receive(:publish).and_raise(StandardError, "Event store down")

        expect(Rails.logger).to receive(:error).with("Failed to publish vote event: Event store down")

        create(:vote, vote_type: "upvote")
      end
    end

    describe "after_destroy :publish_vote_removed_event" do
      it "publishes an EventVoteRemoved event when destroying a vote" do
        # Mock the event store to succeed
        event_store = instance_double("RailsEventStore::Client")
        allow(Rails.configuration).to receive(:event_store).and_return(event_store)
        allow(event_store).to receive(:publish)

        user = create(:user)
        event = create(:event)
        vote = create(:vote, user: user, event: event, vote_type: "upvote")

        # Verify EventUpvoted was published during creation (1 time)
        expect(event_store).to have_received(:publish).with(
          an_instance_of(EventUpvoted),
          stream_name: "Vote$#{vote.id}"
        ).once

        vote.destroy

        # Verify EventVoteRemoved was published during destruction (1 time)
        expect(event_store).to have_received(:publish).with(
          an_instance_of(EventVoteRemoved),
          stream_name: "Vote$#{vote.id}"
        ).once
      end

      it "logs an error if publishing fails" do
        event_store = instance_double("RailsEventStore::Client")
        allow(Rails.configuration).to receive(:event_store).and_return(event_store)

        # Allow publish to succeed on first call (create), but fail on second call (destroy)
        call_count = 0
        allow(event_store).to receive(:publish) do
          call_count += 1
          if call_count == 1
            true # Success on create
          else
            raise StandardError, "Event store down" # Fail on destroy
          end
        end

        expect(Rails.logger).to receive(:error).with("Failed to publish vote removed event: Event store down")

        vote = create(:vote)
        vote.destroy
      end
    end
  end

  describe "instance methods" do
    describe "#update_event_counts" do
      it "updates the event's vote counts" do
        event = create(:event)
        vote = create(:vote, event: event)

        # Call private method using send
        expect(event).to receive(:update_votes_count)

        vote.send(:update_event_counts)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe VoteRecorder, type: :service do
  let!(:user) { create(:user) }
  let!(:event) { create(:event) }

  # Mock the event store since Vote model has callbacks
  let(:event_store) { instance_double("RailsEventStore::Client") }

  before do
    allow(Rails.configuration).to receive(:event_store).and_return(event_store)
    allow(event_store).to receive(:publish)
  end

  describe "#call" do
    context "when user has not voted" do
      it "creates a new upvote" do
        result = described_class.new(user: user, event: event, vote_type: "upvote").call

        expect(result.action).to eq("created")
        expect(result.event.reload.upvotes_count).to eq(1)
        expect(result.user_vote).to eq("upvote")
        expect(Vote.count).to eq(1)
      end

      it "creates a new downvote" do
        result = described_class.new(user: user, event: event, vote_type: "downvote").call

        expect(result.action).to eq("created")
        expect(result.event.reload.downvotes_count).to eq(1)
        expect(result.user_vote).to eq("downvote")
        expect(Vote.count).to eq(1)
      end
    end

    context "when user has already voted with the same type" do
      it "removes the existing vote" do
        create(:vote, user: user, event: event, vote_type: "upvote")

        result = described_class.new(user: user, event: event, vote_type: "upvote").call

        expect(result.action).to eq("removed")
        expect(result.event.reload.upvotes_count).to eq(0)
        expect(result.user_vote).to be_nil
        expect(Vote.count).to eq(0)
      end
    end

    context "when user has already voted with a different type" do
      it "changes the existing vote" do
        create(:vote, user: user, event: event, vote_type: "upvote")

        result = described_class.new(user: user, event: event, vote_type: "downvote").call

        expect(result.action).to eq("changed")
        expect(result.event.reload.downvotes_count).to eq(1)
        expect(result.event.reload.upvotes_count).to eq(0)
        expect(result.user_vote).to eq("downvote")
        expect(Vote.count).to eq(1)
      end
    end

    context "when vote type is invalid" do
      it "raises InvalidVoteType error" do
        expect {
          described_class.new(user: user, event: event, vote_type: "invalid").call
        }.to raise_error(VoteRecorder::InvalidVoteType, "Invalid vote type")
      end
    end

    context "when database transaction fails" do
      it "rolls back the transaction" do
        allow(Vote).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          described_class.new(user: user, event: event, vote_type: "upvote").call
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Vote.count).to eq(0)
        expect(event.reload.upvotes_count).to eq(0)
      end
    end
  end
end

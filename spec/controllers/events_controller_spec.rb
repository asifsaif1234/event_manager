# spec/controllers/events_controller_spec.rb
require "rails_helper"

RSpec.describe EventsController, type: :controller do
  let(:user)  { create(:user) }
  let(:event) { create(:event, state: "published", availability: true, start_date: 1.day.from_now) }

  def sign_in(user)
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:user_signed_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  def sign_out
    allow(controller).to receive(:authenticate_user!).and_return(false)
    allow(controller).to receive(:user_signed_in?).and_return(false)
    allow(controller).to receive(:current_user).and_return(nil)
  end

  describe "GET #index" do
    before { create(:event, state: "published", availability: true, start_date: 1.day.from_now) }

    context "when signed out" do
      before { sign_out }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "does not assign @user_votes" do
        get :index
        expect(assigns(:user_votes)).to be_nil
      end
    end

    context "when signed in" do
      before { sign_in(user) }

      it "assigns @user_votes keyed by event_id" do
        vote = create(:vote, user: user, event: event, vote_type: "upvote")
        get :index
        expect(assigns(:user_votes)).to include(event.id => vote)
      end
    end
  end

  describe "POST #ingest" do
    it "enqueues EventIngestionJob with limit: 10" do
      expect(EventIngestionJob).to receive(:perform_later).with(limit: 10)
      post :ingest
    end

    it "redirects to events_path with a flash notice" do
      allow(EventIngestionJob).to receive(:perform_later)
      post :ingest
      expect(response).to redirect_to(events_path)
      expect(flash[:notice]).to match(/background/i)
    end
  end

  describe "POST #ingest_all" do
    it "enqueues EventIngestionJob with no args" do
      expect(EventIngestionJob).to receive(:perform_later).with(no_args)
      post :ingest_all
    end

    it "redirects with a flash notice" do
      allow(EventIngestionJob).to receive(:perform_later)
      post :ingest_all
      expect(response).to redirect_to(events_path)
      expect(flash[:notice]).to match(/several minutes/i)
    end
  end

  describe "GET #sync_status" do
    context "when ingestion has run" do
      before do
        allow(Rails.cache).to receive(:read).with("last_event_ingestion").and_return(
          { timestamp: "2026-08-26T12:00:00Z", result: { created: 5, updated: 2 } }
        )
      end

      it "returns success with last_run and results" do
        get :sync_status
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["last_run"]).to eq("2026-08-26T12:00:00Z")
        expect(json["results"]).to eq({ "created" => 5, "updated" => 2 })
      end
    end

    context "when ingestion has never run" do
      before { allow(Rails.cache).to receive(:read).with("last_event_ingestion").and_return(nil) }

      it "returns success: false" do
        get :sync_status
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["message"]).to match(/no ingestion/i)
      end
    end
  end

  describe "POST #vote" do
    context "when not authenticated" do
      before { sign_out }

      it "returns an error response" do
        # Mock VoteRecorder to raise InvalidVoteType
        allow(VoteRecorder).to receive(:new).and_raise(VoteRecorder::InvalidVoteType, "Invalid vote type")

        post :vote, params: { id: event.id, vote_type: "upvote" }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to eq("Invalid vote type")
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      context "with a valid vote_type" do
        let(:result) do
          double(
            "VoteResult",
            action: "created",
            event: event,
            user_vote: "upvote"
          )
        end

        before do
          allow(event).to receive(:upvotes_count).and_return(3)
          allow(event).to receive(:downvotes_count).and_return(1)
          allow(event).to receive(:total_score).and_return(2)

          allow(Event).to receive(:find).with(event.id.to_s).and_return(event)

          allow_any_instance_of(VoteRecorder).to receive(:call).and_return(result)
        end

        it "returns success: true with vote counts and action" do
          post :vote, params: { id: event.id, vote_type: "upvote" }

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json).to include(
            "success"     => true,
            "upvotes"     => 3,
            "downvotes"   => 1,
            "total_score" => 2,
            "user_vote"   => "upvote",
            "action"      => "created"
          )
          expect(json["message"]).to match(/added/i)
        end
      end

      context "when the service raises InvalidVoteType" do
        before do
          allow(Event).to receive(:find).and_return(event)
          allow_any_instance_of(VoteRecorder).to receive(:call).and_raise(VoteRecorder::InvalidVoteType, "Invalid vote type")
        end

        it "returns 422 with the error message" do
          post :vote, params: { id: event.id, vote_type: "sideways" }

          json = JSON.parse(response.body)
          expect(response).to have_http_status(:unprocessable_content)
          expect(json).to eq("success" => false, "error" => "Invalid vote type")
        end
      end

      context "when the event does not exist" do
        before { allow(Event).to receive(:find).and_raise(ActiveRecord::RecordNotFound) }

        it "returns 404" do
          post :vote, params: { id: -1, vote_type: "upvote" }

          json = JSON.parse(response.body)
          expect(response).to have_http_status(:not_found)
          expect(json).to eq("success" => false, "error" => "Event not found")
        end
      end

      context "when the service raises an unexpected error" do
        before do
          allow(Event).to receive(:find).and_return(event)
          allow_any_instance_of(VoteRecorder).to receive(:call).and_raise(StandardError, "DB connection lost")
        end

        it "returns 422 with the raw error message" do
          post :vote, params: { id: event.id, vote_type: "upvote" }

          json = JSON.parse(response.body)
          expect(response).to have_http_status(:unprocessable_content)
          expect(json).to eq("success" => false, "error" => "DB connection lost")
        end
      end
    end
  end
end

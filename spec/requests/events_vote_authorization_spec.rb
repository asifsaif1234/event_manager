require "rails_helper"

RSpec.describe "POST /events/:id/vote authorization", type: :request do
  let!(:event) { create(:event, state: "published", availability: true, start_date: 2.days.from_now) }

  context "when the request carries no session at all (a genuinely anonymous client)" do
    it "does not persist a vote" do
      expect {
        post "/events/#{event.id}/vote", params: { vote_type: "upvote" }
      }.not_to change { event.votes.count }
    end

    it "redirects rather than returning the vote JSON payload" do
      post "/events/#{event.id}/vote", params: { vote_type: "upvote" }

      expect(response).to have_http_status(:found) # 302
      expect(response).to redirect_to(root_path)
    end

    it "sets the expected flash alert" do
      post "/events/#{event.id}/vote", params: { vote_type: "upvote" }

      expect(flash[:alert]).to eq("Please sign in to vote.")
    end

    it "remembers the original path to return to after sign-in" do
      post "/events/#{event.id}/vote", params: { vote_type: "upvote" }

      expect(session[:return_to]).to eq("/events/#{event.id}/vote")
    end
  end

  context "when a session cookie exists but points at no real user (edge case)" do
    it "still does not persist a vote" do
      
      get "/test_sign_in/999999"

      expect {
        post "/events/#{event.id}/vote", params: { vote_type: "upvote" }
      }.not_to change { event.votes.count }
    end
  end
end

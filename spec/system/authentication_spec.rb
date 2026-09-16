require "rails_helper"

RSpec.describe "Authentication", type: :system do
  let(:user) { create(:user, first_name: "Asif") }
  let!(:event) { create(:event, start_date: 2.days.from_now) }

  describe "signed-in state" do
    it "unlocks voting once a session is established" do
      sign_in_as(user)
      visit root_path

      card = find(".event-card[data-event-id='#{event.id}']")
      upvote_btn = card.find(".upvote-btn")

      expect(upvote_btn["data-authenticated"]).to eq("true")
    end
  end

  describe "signed-out state" do
    it "marks vote buttons as unauthenticated for an anonymous visitor" do
      visit root_path

      card = find(".event-card[data-event-id='#{event.id}']")
      upvote_btn = card.find(".upvote-btn")

      expect(upvote_btn["data-authenticated"]).to eq("false")
    end
  end

  describe "authenticate_user! redirect (server-side gate)" do
    it "never persists a vote for an anonymous visitor, regardless of client-side JS", js: true do
      visit root_path
      card = find(".event-card[data-event-id='#{event.id}']")
      card.find(".upvote-btn").click

      expect(page).to have_content("Sign In Required")
      expect(event.reload.votes.count).to eq(0)
    end
  end

  describe "sign-out clears the session" do
    before do
      stub_request(:post, %r{https://api\.clerk\.com/v1/sessions/.+/revoke})
        .to_return(status: 200, body: "", headers: {})
    end

    it "removes session[:user_id] so vote buttons revert to unauthenticated" do
      sign_in_as(user)
      visit root_path
      card = find(".event-card[data-event-id='#{event.id}']")
      expect(card.find(".upvote-btn")["data-authenticated"]).to eq("true")

      sign_out_of_system
      visit root_path

      card = find(".event-card[data-event-id='#{event.id}']")
      expect(card.find(".upvote-btn")["data-authenticated"]).to eq("false")
    end
  end
end

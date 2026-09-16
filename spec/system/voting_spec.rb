# spec/system/voting_spec.rb
require "rails_helper"

RSpec.describe "Voting on events", type: :system, js: true do
  let(:user)  { create(:user) }
  let!(:event) do
    create(:event,
      title: "Techtown Conference",
      state: "published",
      availability: true,
      start_date: 3.days.from_now)
  end

  def event_card
    find(".event-card[data-event-id='#{event.id}']")
  end

  def upvote_button
    within(event_card) { find(".upvote-btn") }
  end

  def downvote_button
    within(event_card) { find(".downvote-btn") }
  end

  def upvote_count
    within(event_card) { find(".upvote-count").text.to_i }
  end

  def downvote_count
    within(event_card) { find(".downvote-count").text.to_i }
  end

  def score
    within(event_card) { find(".vote-score").text.to_i }
  end

  context "when signed in" do
    before { sign_in_as(user) }

    it "casts a new upvote" do
      visit root_path

      upvote_button.click

      expect(page).to have_content("Vote added successfully")
      expect(event.votes.count).to eq(1)
      expect(upvote_count).to eq(1)
      expect(score).to eq(1)
      expect(upvote_button[:class]).to include("bg-green-100")
    end

    it "casts a new downvote" do
      visit root_path

      downvote_button.click

      expect(page).to have_content("Vote added successfully")
      expect(downvote_count).to eq(1)
      expect(score).to eq(-1)
      expect(downvote_button[:class]).to include("bg-red-100")
    end

    it "removes an upvote when clicking the same vote again (toggle off)" do
      create(:vote, user: user, event: event, vote_type: "upvote")
      visit root_path

      upvote_button.click

      expect(page).to have_content("Vote removed successfully")
      expect(event.votes.count).to eq(0)
      expect(upvote_count).to eq(0)
      expect(upvote_button[:class]).not_to include("bg-green-100")
    end

    it "switches an existing upvote to a downvote" do
      create(:vote, user: user, event: event, vote_type: "upvote")
      visit root_path

      downvote_button.click

      expect(page).to have_content("Vote changed to downvote")
      expect(upvote_count).to eq(0)
      expect(downvote_count).to eq(1)
      expect(downvote_button[:class]).to include("bg-red-100")
      expect(upvote_button[:class]).not_to include("bg-green-100")
    end

    it "persists the vote state across a page reload" do
      upvote_button.click
      expect(page).to have_content("Vote added successfully")

      visit root_path

      expect(upvote_button[:class]).to include("bg-green-100")
      expect(upvote_count).to eq(1)
    end

    it "rolls back the optimistic UI update if the request fails" do

      allow_any_instance_of(VoteRecorder).to receive(:call)
        .and_raise(StandardError, "DB connection lost")

      visit root_path
      upvote_button.click

      expect(page).to have_content("Something went wrong")
      expect(upvote_count).to eq(0)
    end
  end

  context "when signed out" do
    it "shows a sign-in prompt modal instead of voting" do
      visit root_path
      upvote_button.click

      expect(page).to have_content("Sign In Required")
      expect(page).to have_content("You need to sign in to vote on events.")
      expect(page).to have_link("Sign In", href: "/sign_in")
      expect(page).to have_link("Sign Up", href: "/sign_up")

      expect(event.votes.count).to eq(0)
    end

    it "closes the sign-in modal via the Cancel button" do
      visit root_path
      upvote_button.click
      expect(page).to have_content("Sign In Required")

      click_button "Cancel"
      expect(page).not_to have_content("Sign In Required")
    end

    it "closes the sign-in modal by clicking the backdrop" do
      visit root_path
      upvote_button.click
      expect(page).to have_content("Sign In Required")

      page.execute_script(<<~JS)
        document.querySelector('.login-modal')
          .dispatchEvent(new MouseEvent('click', { bubbles: true }))
      JS

      expect(page).not_to have_content("Sign In Required")
    end
  end
end

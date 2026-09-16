# spec/system/events_index_spec.rb
require "rails_helper"

RSpec.describe "Events index page", type: :system do
  describe "with published, available, upcoming events" do
    let!(:free_event) do
      create(:event,
        title: "Copenhagen Jazz Night",
        state: "published",
        availability: true,
        start_date: 2.days.from_now,
        price_amount_in_cents: 0,
        location_data: { "location_name" => "Vega Hall" },
        categorization_data: { "category_localized" => "Music" })
    end

    let!(:paid_event) do
      create(:event,
        title: "Startup Founders Meetup",
        state: "published",
        availability: true,
        start_date: 5.days.from_now,
        price_amount_in_cents: 15_000,
        price_currency: "DKK",
        location_data: { "location_name" => "Founders House" },
        categorization_data: { "category_localized" => "Business" })
    end

    # Should NOT show up
    let!(:draft_event)     { create(:event, :draft, title: "Hidden Draft Event") }
    let!(:past_event)      { create(:event, :past_event, title: "Old Conference") }
    let!(:sold_out_event)  { create(:event, availability: false, title: "Sold Out Show") }

    it "lists only published, available, upcoming events" do
      visit root_path

      expect(page).to have_content("Copenhagen Jazz Night")
      expect(page).to have_content("Startup Founders Meetup")

      expect(page).not_to have_content("Hidden Draft Event")
      expect(page).not_to have_content("Old Conference")
      expect(page).not_to have_content("Sold Out Show")
    end

    it "shows the correct event count in the header" do
      visit root_path
      expect(page).to have_content("2 events found")
    end

    it "formats a free event's price as 'Free'" do
      visit root_path
      within_event_card(free_event) { expect(page).to have_content("Free") }
    end

    it "formats a paid event's price with amount and currency" do
      visit root_path
      within_event_card(paid_event) { expect(page).to have_content("150.0 DKK") }
    end

    it "shows location and category for each event" do
      visit root_path
      within_event_card(free_event) do
        expect(page).to have_content("Vega Hall")
        expect(page).to have_content("Music")
      end
    end

    it "shows the formatted start date" do
      visit root_path
      within_event_card(free_event) do
        expect(page).to have_content(free_event.start_date.strftime("%b %d, %Y"))
      end
    end
  end

  describe "with no events" do
    it "shows the empty state" do
      visit root_path

      expect(page).to have_content("No events found")
      expect(page).to have_content('Click "Sync Events" to fetch events from Billetto')
    end
  end

  describe "sync action buttons" do
    it "triggers a recent sync and shows a background-processing flash" do
      visit root_path
      click_button "Sync Recent"

      expect(page).to have_content(/background/i)
    end

    it "triggers a full sync and shows a several-minutes flash" do
      visit root_path
      click_button "Sync All"

      expect(page).to have_content(/several minutes/i)
    end
  end

  def within_event_card(event, &block)
    card = find(".event-card[data-event-id='#{event.id}']")
    within(card, &block)
  end
end

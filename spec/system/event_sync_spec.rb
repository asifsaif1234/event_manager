require "rails_helper"

RSpec.describe "Event syncing from Billetto", type: :system do
  describe "triggering ingestion", js: false do
    it "enqueues a limited ingestion job via 'Sync Recent'" do
      expect(EventIngestionJob).to receive(:perform_later).with(limit: 10)

      visit root_path
      click_button "Sync Recent"

      expect(page).to have_content(/Event ingestion started in background/i)
    end

    it "enqueues a full ingestion job via 'Sync All'" do
      expect(EventIngestionJob).to receive(:perform_later).with(no_args)

      visit root_path
      click_button "Sync All"

      expect(page).to have_content(/Full event ingestion started/i)
    end
  end

  describe "checking sync status", type: :system, js: true do
    context "when an ingestion has previously run" do
      before do
        Rails.cache.write("last_event_ingestion", {
          timestamp: 1.hour.ago.iso8601,
          result: { created: 4, updated: 2, failed: 0, errors: [] }
        })
      end

      it "displays the last run time and results after clicking Check Sync Status" do
        visit root_path

        expect(page).to have_selector("[data-sync-status-target='display']", visible: false)

        click_button "Check Sync Status"

        display = find("[data-sync-status-target='display']")
        expect(display).to be_visible
        within(display) do
          expect(page).to have_content("Last Run:")
          expect(page).to have_content('"created": 4')
          expect(page).to have_content('"updated": 2')
        end
      end

      it "hides the status panel again via the close (×) button" do
        visit root_path
        click_button "Check Sync Status"
        expect(find("[data-sync-status-target='display']")).to be_visible

        find("button", text: "×").click
        expect(page).to have_selector("[data-sync-status-target='display']", visible: false)
      end
    end

    context "when no ingestion has ever run" do
      before { Rails.cache.delete("last_event_ingestion") }

      it "shows a 'no ingestion has been run yet' message" do
        visit root_path
        click_button "Check Sync Status"

        within("[data-sync-status-target='display']") do
          expect(page).to have_content(/no ingestion has been run yet/i)
        end
      end
    end
  end

  describe "end-to-end: ingest then browse the synced event", js: false do
    it "makes a newly ingested event visible on the index page" do
      api_event = {
        "id" => "evt_e2e_001",
        "title" => "Live-Synced Meetup",
        "startdate" => 4.days.from_now.iso8601,
        "state" => "published",
        "availability" => true,
        "minimum_price" => { "amount_in_cents" => 0, "currency" => "DKK" },
        "organiser" => { "name" => "Community Org" },
        "location" => { "location_name" => "Town Hall" },
        "categorization" => { "category_localized" => "Community" },
        "object" => "event",
        "kind" => "public"
      }

      events_service = instance_double(Billeto::EventsService)
      allow(Billeto::EventsService).to receive(:new).and_return(events_service)
      allow(events_service).to receive(:fetch_events)
        .and_return(success: true, data: { "data" => [ api_event ], "has_more" => false })

      # Run the ingestion synchronously in-process instead of round-tripping
      # through ActiveJob/Sidekiq, then verify the UI reflects the result.
      Billeto::EventIngestionService.new.ingest(limit: 10)

      visit root_path
      expect(page).to have_content("Live-Synced Meetup")
      expect(page).to have_content("Town Hall")
    end
  end
end

require 'rails_helper'

RSpec.describe EventUpdater do
  let(:event) { create(:event) }
  let(:api_event) do
    {
      "id" => event.event_id,
      "title" => "Updated Title",
      "description" => "Updated Description",
      "startdate" => event.start_date.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "enddate" => event.end_date.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "image_link" => "https://example.com/new.jpg",
      "url" => "https://example.com/new",
      "state" => "published",
      "availability" => true,
      "minimum_price" => { "amount_in_cents" => 2000, "currency" => "DKK" },
      "organiser" => { "name" => "New Org" },
      "location" => { "city" => "Aarhus" },
      "categorization" => { "category" => "Tech" },
      "organization" => { "name" => "New Org" }
    }
  end

  describe ".changed?" do
    it "returns true if any attribute changed" do
      expect(EventUpdater.changed?(event, api_event)).to be true
    end

    it "returns false if no attributes changed" do
      # FIX: Convert ALL attributes to match the API format exactly
      same_event = api_event.merge(
        "title" => event.title,
        "description" => event.description,
        "image_link" => event.image_link,
        "url" => event.url,
        "state" => event.state,
        "availability" => event.availability,
        "startdate" => event.start_date.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "enddate" => event.end_date.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "minimum_price" => {
          "amount_in_cents" => event.price_amount_in_cents,
          "currency" => event.price_currency
        },
        # Set JSON fields to match what EventUpdater expects
        "organiser" => event.organiser_data,
        "location" => event.location_data,
        "categorization" => event.categorization_data,
        "organization" => event.organization_data
      )
      expect(EventUpdater.changed?(event, same_event)).to be false
    end
  end

  describe ".assign_attributes" do
    it "assigns all attributes from API data" do
      EventUpdater.assign_attributes(event, api_event)

      expect(event.title).to eq("Updated Title")
      expect(event.description).to eq("Updated Description")
      expect(event.image_link).to eq("https://example.com/new.jpg")
      expect(event.url).to eq("https://example.com/new")
      expect(event.price_amount_in_cents).to eq(2000)
      expect(event.price_currency).to eq("DKK")
      expect(event.organiser_data).to eq({ "name" => "New Org" })
      expect(event.location_data).to eq({ "city" => "Aarhus" })
      expect(event.categorization_data).to eq({ "category" => "Tech" })
      expect(event.organization_data).to eq({ "name" => "New Org" })
    end
  end
end

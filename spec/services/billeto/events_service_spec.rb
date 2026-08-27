require 'rails_helper'

RSpec.describe Billeto::EventsService do
  let(:service) { described_class.new }

  describe "#fetch_events" do
    it "calls the API with correct headers and query params" do
      allow(service.class).to receive(:get).and_return(
        instance_double(HTTParty::Response, success?: true, parsed_response: { "data" => [] })
      )

      result = service.fetch_events(limit: 50, after: "abc123")

      expect(service.class).to have_received(:get).with(
        "/public/events",
        headers: { "Api-Keypair" => Rails.application.config.billetto[:api_keypair], "Content-Type" => "application/json" },
        query: { limit: 50, after: "abc123" }
      )
      expect(result[:success]).to be true
      expect(result[:data]).to eq({ "data" => [] })
    end

    it "does not include after param if not present" do
      allow(service.class).to receive(:get).and_return(
        instance_double(HTTParty::Response, success?: true, parsed_response: { "data" => [] })
      )

      service.fetch_events(limit: 50)

      expect(service.class).to have_received(:get).with(
        "/public/events",
        headers: anything,
        query: { limit: 50 }
      )
    end
  end

  describe "#fetch_all_events" do
    it "fetches all pages of events" do
      page1_response = instance_double(HTTParty::Response, success?: true, parsed_response: {
        "data" => [ { "id" => "1" }, { "id" => "2" } ],
        "has_more" => true
      })
      page2_response = instance_double(HTTParty::Response, success?: true, parsed_response: {
        "data" => [ { "id" => "3" } ],
        "has_more" => false
      })

      allow(service).to receive(:fetch_events).and_return(
        { success: true, data: page1_response.parsed_response },
        { success: true, data: page2_response.parsed_response }
      )

      result = service.fetch_all_events

      expect(result.length).to eq(3)
      expect(result.map { |e| e["id"] }).to eq([ "1", "2", "3" ])
      expect(service).to have_received(:fetch_events).with(limit: 100, after: nil)
      expect(service).to have_received(:fetch_events).with(limit: 100, after: "2")
    end

    it "stops fetching on error" do
      allow(service).to receive(:fetch_events).and_return(
        { success: false, error: "API error" }
      )

      # Directly mock Rails.logger
      allow(Rails.logger).to receive(:error)
      result = service.fetch_all_events

      expect(result).to eq([])
      expect(Rails.logger).to have_received(:error).with("Failed to fetch page 1: API error")
    end
  end
end

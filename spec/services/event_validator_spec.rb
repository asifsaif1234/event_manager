require 'rails_helper'

RSpec.describe EventValidator do
  let(:valid_event) do
    {
      "id" => "event_123",
      "title" => "Test Event",
      "startdate" => "2024-01-01T10:00:00Z",
      "state" => "published"
    }
  end

  describe ".validate" do
    it "returns success for valid data" do
      expect(EventValidator.validate(valid_event)).to eq({ success: true })
    end

    it "returns error for missing required fields" do
      invalid_event = valid_event.merge("title" => nil)
      result = EventValidator.validate(invalid_event)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Missing required fields: title")
    end

    it "returns error for invalid date format" do
      invalid_event = valid_event.merge("startdate" => "not-a-date")
      result = EventValidator.validate(invalid_event)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Invalid date format")
    end
  end
end

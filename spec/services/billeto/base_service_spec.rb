require 'rails_helper'

RSpec.describe Billeto::BaseService do
  let(:service) { described_class.new }

  describe "#initialize" do
    it "sets up the base URI and API keypair" do
      expect(service.class.base_uri).to eq(Rails.application.config.billetto[:base_url])
    end
  end

  describe "#handle_response" do
    let(:success_response) { instance_double(HTTParty::Response, success?: true, parsed_response: { "data" => [] }) }
    let(:error_response) { instance_double(HTTParty::Response, success?: false, code: 404, parsed_response: { "error" => "Not Found" }) }

    it "returns success hash for successful responses" do
      expect(service.send(:handle_response, success_response)).to eq(
        { success: true, data: { "data" => [] } }
      )
    end

    it "returns error hash for failed responses" do
      expect(service.send(:handle_response, error_response)).to eq(
        { success: false, error: "Resource not found.", status: 404 }
      )
    end

    it "handles network errors gracefully" do
      bad_response = double("HTTParty::Response")
      allow(bad_response).to receive(:success?).and_raise(StandardError, "Connection refused")

      expect(service.send(:handle_response, bad_response)).to eq(
        { success: false, error: "Connection error: Connection refused" }
      )
    end
  end

  describe "#error_message" do
    it "returns specific messages for status codes" do
      expect(service.send(:error_message, instance_double(HTTParty::Response, code: 401))).to eq("Authentication failed. Check your API key and secret.")
      expect(service.send(:error_message, instance_double(HTTParty::Response, code: 403))).to eq("Access forbidden. Your API key doesn't have permission.")
      expect(service.send(:error_message, instance_double(HTTParty::Response, code: 404))).to eq("Resource not found.")
      expect(service.send(:error_message, instance_double(HTTParty::Response, code: 422))).to eq("Validation error. The request data is invalid.")
      expect(service.send(:error_message, instance_double(HTTParty::Response, code: 429))).to eq("Rate limit exceeded. Please try again later.")
      expect(service.send(:error_message, instance_double(HTTParty::Response, code: 500))).to eq("Billetto server error. Please try again later.")
    end
  end
end

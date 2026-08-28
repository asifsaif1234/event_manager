# spec/jobs/event_ingestion_job_spec.rb
require "rails_helper"

RSpec.describe EventIngestionJob, type: :job do
  let(:service) { instance_double(Billeto::EventIngestionService) }

  before do
    allow(Billeto::EventIngestionService).to receive(:new).and_return(service)
  end

  describe "#perform" do
    context "when the service returns a successful result" do
      let(:result) { { created: 5, updated: 3, failed: 0, errors: [] } }

      before do
        allow(service).to receive(:ingest).and_return(result)
      end

      it "writes the result to Rails.cache" do
        expect(Rails.cache).to receive(:write).with(
          "last_event_ingestion",
          hash_including(
            result: result,
            timestamp: kind_of(Time)
          ),
          expires_in: 24.hours
        )

        described_class.perform_now(limit: 10)
      end

      it "returns the result merged with duration" do
        start_time = Time.zone.parse("2026-01-01 12:00:00")
        end_time = start_time + 2.seconds

        # Mock Time.current to return start_time first, then end_time
        allow(Time).to receive(:current).and_return(start_time, end_time)

        returned = described_class.perform_now(limit: 10)

        expect(returned[:created]).to eq(5)
        expect(returned[:updated]).to eq(3)
        expect(returned[:failed]).to eq(0)
        expect(returned[:duration]).to eq(2.0)
      end

      it "logs the success messages" do
        allow_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info)
        allow_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:error)

        expect_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info).with("Starting event ingestion job...")
        expect_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info).with(/Ingestion completed/)
        expect_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info).with("Created: 5, Updated: 3")

        described_class.perform_now(limit: 10)
      end

      it "does not log failure if failed count is 0" do
        allow_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info)

        expect_any_instance_of(ActiveSupport::BroadcastLogger).not_to receive(:info).with("Failed: 0")

        described_class.perform_now(limit: 10)
      end
    end

    context "when the service returns a result with failures" do
      let(:result) { { created: 2, updated: 0, failed: 3, errors: [ "Error 1" ] } }

      before do
        allow(service).to receive(:ingest).and_return(result)
      end

      it "logs the failure count" do
        allow_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info)

        expect_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:info).with("Failed: 3")

        described_class.perform_now
      end
    end

    context "when the service raises an error" do
      before do
        allow(service).to receive(:ingest).and_raise(StandardError, "API connection failed")
      end

      it "logs the error" do
        allow_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:error)

        expect_any_instance_of(ActiveSupport::BroadcastLogger).to receive(:error).with("Ingestion job failed: API connection failed")

        expect {
          described_class.perform_now
        }.to raise_error(StandardError, "API connection failed")
      end
    end

    context "when limit is provided" do
      let(:result) { { created: 1, updated: 0, failed: 0, errors: [] } }

      before do
        allow(service).to receive(:ingest).with(limit: 20).and_return(result)
      end

      it "passes the limit to the service" do
        expect(service).to receive(:ingest).with(limit: 20)

        described_class.perform_now(limit: 20)
      end
    end

    context "when limit is not provided" do
      let(:result) { { created: 1, updated: 0, failed: 0, errors: [] } }

      before do
        allow(service).to receive(:ingest).with(limit: nil).and_return(result)
      end

      it "calls the service with limit: nil" do
        expect(service).to receive(:ingest).with(limit: nil)

        described_class.perform_now
      end
    end
  end
end

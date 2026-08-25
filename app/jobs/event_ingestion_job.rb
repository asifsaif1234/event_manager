class EventIngestionJob < ApplicationJob
  queue_as :default

  def perform(limit: nil)
    Rails.logger.info "Starting event ingestion job..."

    start_time = Time.current
    service = Billeto::EventIngestionService.new
    result = service.ingest(limit: limit)
    duration = Time.current - start_time

    Rails.logger.info "Ingestion completed in #{duration} seconds"
    Rails.logger.info "Created: #{result[:created]}, Updated: #{result[:updated]}"
    Rails.logger.info "Failed: #{result[:failed]}" if result[:failed] > 0

    Rails.cache.write("last_event_ingestion", {
      result: result,
      timestamp: Time.current
    }, expires_in: 24.hours)

    result.merge(duration: duration)
  rescue StandardError => e
    Rails.logger.error "Ingestion job failed: #{e.message}"
    raise e
  end
end

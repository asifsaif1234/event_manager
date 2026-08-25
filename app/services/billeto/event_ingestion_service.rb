module Billeto
  class EventIngestionService
    attr_reader :events_service, :results

    def initialize
      @events_service = EventsService.new
      @results = { created: 0, updated: 0, failed: 0, errors: [] }
    end

    def ingest(limit: nil)
      # Get events
      events_data = fetch_events(limit: limit)
      
      # Check for error
      if events_data.is_a?(Hash) && events_data[:error]
        return events_data
      end

      # Process each event
      events_data.each do |api_event|
        process_and_save_event(api_event)
      end

      results
    rescue StandardError => e
      { error: e.message }
    end

    private

    def fetch_events(limit: nil)
      if limit.present?
        response = events_service.fetch_events(limit: limit)
        return { error: response[:error] } unless response[:success]
        response[:data]['data'] || []
      else
        events_service.fetch_all_events
      end
    end

    def process_and_save_event(api_event)
      # Validate API data
      validation = EventValidator.validate(api_event)
      if !validation[:success]
        results[:failed] += 1
        results[:errors] << validation[:error]
        return
      end

      # Find or initialize event
      event = Event.find_or_initialize_by(event_id: api_event["id"])

      # Check if data changed
      if event.persisted? && !EventUpdater.changed?(event, api_event)
        results[:updated] += 1
        return
      end

      # Assign and save
      EventUpdater.assign_attributes(event, api_event)
      event.last_synced_at = Time.current

      if event.save
        results[:created] += 1 if event.previous_changes.any?
      else
        results[:failed] += 1
        results[:errors] << event.errors.full_messages.join(", ")
      end
    rescue StandardError => e
      results[:failed] += 1
      results[:errors] << e.message
    end
  end
end
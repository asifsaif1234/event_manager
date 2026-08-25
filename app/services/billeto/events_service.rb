module Billeto
  class EventsService < BaseService
    def fetch_events(limit: 50, after: nil)
      query_params = { limit: limit }
      query_params[:after] = after if after.present?

      response = self.class.get(
        '/public/events',
        headers: headers,
        query: query_params
      )

      handle_response(response)
    end

    def fetch_all_events
      all_events = []
      after = nil
      page = 1

      loop do
        Rails.logger.info "Fetching Billetto events page #{page}..."
        response = fetch_events(limit: 100, after: after)
        
        unless response[:success]
          Rails.logger.error "Failed to fetch page #{page}: #{response[:error]}"
          break
        end

        events = response[:data]['data'] || []
        break if events.empty?

        all_events.concat(events)
        
        break unless response[:data]['has_more']
        after = events.last['id']
        page += 1
      end

      all_events
    end
  end
end
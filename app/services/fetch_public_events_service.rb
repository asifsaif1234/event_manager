class FetchPublicEventsService
  # Previous approach
  include HTTParty
  base_uri Rails.application.config.billetto[:base_url]

  def initialize
    @api_keypair = Rails.application.config.billetto[:api_keypair]
  end

  def fetch_events(limit: 50, after: nil)
    query_params = { limit: limit }
    query_params[:after] = after if after.present?

    response = self.class.get(
      "/public/events",
      headers: { "Api-Keypair" => @api_keypair },
      query: query_params
    )

    handle_response(response)
  rescue StandardError => e
    { success: false, error: "Connection error: #{e.message}" }
  end

  def fetch_all_events
    all_events = []
    after = nil
    page = 1

    loop do
      Rails.logger.info "Fetching page #{page}..."
      response = fetch_events(limit: 100, after: after)

      unless response[:success]
        Rails.logger.error "Failed to fetch page #{page}: #{response[:error]}"
        break
      end

      events = response[:data]["data"] || []
      break if events.empty?

      all_events.concat(events)

      break unless response[:data]["has_more"]
      after = events.last["id"]
      page += 1
    end

    all_events
  end

  # def fetch_events(limit: 50, after: nil)
  #   query_params = { limit: limit }
  #   query_params[:after] = after if after.present?

  #   response = self.class.get(
  #     "/public/events",
  #     headers: { "Api-Keypair" => @api_keypair },
  #     query: query_params
  #   )

  #   handle_response(response)
  # rescue StandardError => e
  #   { success: false, error: "Connection error: #{e.message}" }
  # end

  private

  def handle_response(response)
    if response.success?
      { success: true, data: response.parsed_response, status: response.code }
    else
      {
        success: false,
        error: error_message(response),
        status: response.code
      }
    end
  end

  def error_message(response)
    case response.code
    when 401 then "Authentication failed. Check your API key and secret."
    when 403 then "Access forbidden. Your API key doesn't have permission."
    when 404 then "Resource not found."
    when 422 then "Validation error. The request data is invalid."
    when 429 then "Rate limit exceeded. Please try again later."
    when 500..599 then "Billetto server error. Please try again later."
    else response.message
    end
  end
end

class FetchPublicEventsService
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

  private

  def handle_response(response)
    # Success case
    if response.success?
      return {
        success: true,
        data: response.parsed_response,
        status: response.code
      }
    end

    # Error cases with specific messages
    error_response = {
      success: false,
      status: response.code,
      error: error_message(response)
    }

    # Add retry info for rate limiting
    if response.code == 429
      error_response[:retry_after] = response.headers["Retry-After"] || 60
    end

    error_response
  end

  def error_message(response)
    case response.code
    when 400
      "Bad request. Please check your parameters."
    when 401
      "Authentication failed. Check your API key and secret in .env file."
    when 403
      "Access forbidden. Your API key doesn't have permission."
    when 404
      "Resource not found."
    when 422
      "Validation error. The request data is invalid."
    when 429
      "Rate limit exceeded. Please wait before trying again."
    when 500, 502, 503, 504
      "Billetto server error. Please try again later."
    else
      "API error: #{response.message}"
    end
  end
end

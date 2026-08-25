module Billeto
  class BaseService
    include HTTParty
    
    def initialize
      @api_keypair = Rails.application.config.billetto[:api_keypair]
      @base_url = Rails.application.config.billetto[:base_url]
      self.class.base_uri(@base_url)
    end

    private

    def headers
      {
        'Api-Keypair' => @api_keypair,
        'Content-Type' => 'application/json'
      }
    end

    def handle_response(response)
      if response.success?
        { success: true, data: response.parsed_response }
      else
        {
          success: false,
          error: error_message(response),
          status: response.code
        }
      end
    rescue StandardError => e
      { success: false, error: "Connection error: #{e.message}" }
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
end
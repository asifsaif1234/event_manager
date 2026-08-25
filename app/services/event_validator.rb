class EventValidator
  REQUIRED_FIELDS = %w[id title startdate state].freeze

  def self.validate(api_event)
    missing = REQUIRED_FIELDS.reject { |field| api_event[field].present? }

    if missing.any?
      return { success: false, error: "Missing required fields: #{missing.join(', ')}" }
    end

    begin
      DateTime.parse(api_event["startdate"])
    rescue ArgumentError
      return { success: false, error: "Invalid date format: #{api_event['startdate']}" }
    end

    { success: true }
  end
end
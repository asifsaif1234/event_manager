# Be sure to restart your server when you modify this file.

Rails.application.config.billetto = {
  api_key: ENV["BILLETTO_ACCESS_KEY"],
  api_secret: ENV["BILLETTO_SECRET_KEY"],
  base_url: ENV["BILLETTO_API_BASE_URL"] || "https://billetto.dk/api/v3"
}

# Validate configuration
if Rails.application.config.billetto[:api_key].blank? || Rails.application.config.billetto[:api_secret].blank?
  Rails.logger.warn "BILLETTO_ACCESS_KEY or BILLETTO_SECRET_KEY is not set"
  Rails.logger.warn "Please set both in your .env file"
end

# Create the API key pair string (key:secret)
Rails.application.config.billetto[:api_keypair] =
  "#{Rails.application.config.billetto[:api_key]}:#{Rails.application.config.billetto[:api_secret]}"

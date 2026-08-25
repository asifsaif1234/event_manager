# config/initializers/clerk.rb
require "clerk"

Clerk.configure do |config|
  config.secret_key = ENV["CLERK_SECRET_KEY"]
  config.publishable_key = ENV["CLERK_PUBLISHABLE_KEY"]
end

# Validate configuration
if ENV["CLERK_SECRET_KEY"].blank? || ENV["CLERK_PUBLISHABLE_KEY"].blank?
  Rails.logger.warn "Clerk credentials are missing!"
end

require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1440,1200")
  # Chrome logs a warning without this in some CI/docker environments
  options.add_argument("--disable-search-engine-choice-screen")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_driver    = :rack_test          # fast, non-JS specs
Capybara.default_max_wait_time = 6               # generous for fetch()-based voting UI
Capybara.server = :puma, { Silent: true }
Capybara.disable_animation = true if Capybara.respond_to?(:disable_animation=)

RSpec.configure do |config|
  # Any spec tagged `js: true` (or under spec/system by default with Rails)
  # runs against a real Chrome browser so Stimulus/fetch-driven voting works.
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end

  # Rails' default system test setup drives everything through Selenium.
  # We instead default to rack_test for speed and only pay the Selenium
  # cost on specs that actually need JS (voting, sync status).
end

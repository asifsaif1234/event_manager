module SystemAuthenticationHelpers
  def sign_in_as(user)
    visit "/test_sign_in/#{user.id}"
  end

  def sign_out_of_system
    visit "/test_sign_out"
  end
end

RSpec.configure do |config|
  config.include SystemAuthenticationHelpers, type: :system

  config.before(:each, type: :system) do
    sign_out_of_system

    if page.driver.respond_to?(:browser)
      begin
        page.driver.browser.manage.delete_all_cookies
      rescue StandardError
        nil # rack_test and other non-Selenium drivers don't expose .manage
      end
    end
  end
end

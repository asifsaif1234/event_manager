RSpec.configure do |config|
  config.before(:each, type: :system) do
    allow_any_instance_of(ApplicationController)
      .to receive(:clerk)
      .and_return(double("Clerk", user: nil, session: nil))
  end

  config.before(:each, type: :request) do
    allow_any_instance_of(ApplicationController)
      .to receive(:clerk)
      .and_return(double("Clerk", user: nil, session: nil))
  end
end

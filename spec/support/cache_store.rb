RSpec.configure do |config|
  config.around(:each, type: :system) do |example|
    original_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      example.run
    ensure
      Rails.cache = original_cache_store
    end
  end
end

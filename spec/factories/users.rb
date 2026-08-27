FactoryBot.define do
  factory :user do
    clerk_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    email { Faker::Internet.unique.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    avatar_url { "https://example.com/avatar.jpg" }
    last_synced_at { Time.current }
  end
end

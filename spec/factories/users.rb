FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    clerk_id { Faker::Alphanumeric.unique.alphanumeric(number: 15) }
  end
end
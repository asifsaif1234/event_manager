FactoryBot.define do
  factory :event do
    event_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    title { Faker::Lorem.sentence(word_count: 5) }
    start_date { Faker::Date.forward(days: 23) }
    end_date { start_date + 2.days }
    state { "published" }
    availability { true }
    description { Faker::Lorem.paragraph(sentence_count: 5) }
    price_amount_in_cents { 0 }
    price_currency { "DKK" }
    image_link { "https://example.com/image.jpg" }
    organiser_data { { "name" => Faker::Name.name } }
    location_data { { "location_name" => Faker::Address.city, "city" => Faker::Address.city, "country" => Faker::Address.country } }
    categorization_data { { "category_localized" => Faker::Commerce.department } }
    organization_data { {} }
  end

  # Traits for specific states
  trait :draft do
    state { "draft" }
  end

  trait :past_event do
    start_date { Faker::Date.backward(days: 10) }
    end_date { start_date + 1.day }
  end
end

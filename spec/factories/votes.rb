FactoryBot.define do
  factory :vote do
    user
    event
    vote_type { "upvote" }

    after(:create) do |vote|
      vote.event.update_votes_count
    end
  end
end

FactoryBot.define do
  factory :actortype do
    sequence(:id) { |n| n + 100 } # start IDs at 101 to avoid 1
    title { Faker::Creature::Cat.registry }

    trait :with_members do
      has_members { true }
    end

    trait :active do
      is_active { true }
    end

    trait :target do
      is_target { true }
    end

    trait :country do
      id { Actor::COUNTRY_TYPE_ID }
      title { "Country" }
    end

    trait :not_a_country do
      title { "Not a Country" }
    end
  end
end

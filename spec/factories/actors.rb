FactoryBot.define do
  factory :actor do
    association(:actortype, :active, :target)
    activity_summary { Faker::Ancient.primordial }
    code { Faker::Beer.name }
    address { Faker::Address.full_address }
    description { Faker::Movies::StarWars.quote }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    prefix { Faker::Name.prefix }
    title { Faker::Creature::Cat.registry }
    is_archive { false }
    private { false }
    draft { true }
    public_api { false }

    trait :country do
      actortype_id { Actor::COUNTRY_TYPE_ID }
    end

    trait :draft do
      draft { true }
    end

    trait :not_draft do
      draft { false }
    end

    trait :is_archive do
      is_archive { true }
    end

    trait :not_is_archive do
      is_archive { false }
    end

    trait :not_private do
      private { false }
    end

    trait :private do
      private { true }
    end

    trait :public do
      public_api { true }
    end

    trait :not_public do
      public_api { false }
    end

    trait :country do
      actortype_id { Actor::COUNTRY_TYPE_ID }
    end
  end
end

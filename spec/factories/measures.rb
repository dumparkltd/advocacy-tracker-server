FactoryBot.define do
  factory :measure do
    title { Faker::Creature::Cat.registry }
    description { Faker::Beer.name }
    association(:measuretype)
    target_date { Faker::Date.forward(days: 450) }

    is_archive { false }
    private { false }
    draft { true }
    public_api { false }

    trait :draft do
      draft { true }
    end

    trait :not_draft do
      draft { false }
    end

    trait :published do
      draft { false }
    end

    trait :without_category do
      categories { [] }
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

    trait :statement do
      measuretype_id { Measure::STATEMENT_TYPE_ID }
    end

    trait :public do
      public_api { true }
    end

    trait :not_public do
      public_api { false }
    end
  end
end

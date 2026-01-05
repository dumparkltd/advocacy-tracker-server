# frozen_string_literal: true

FactoryBot.define do
  factory :indicator do
    title { Faker::Lorem.sentence }
    description { Faker::Hipster.sentence }

    is_archive { false }
    private { false }
    draft { true }
    public_api { false }

    trait :without_measure do
      measures { [] }
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

    trait :private do
      private { true }
    end

    trait :not_private do
      private { false }
    end

    trait :public do
      public_api { true }
    end

    trait :not_public do
      public_api { false }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :indicator do
    title { Faker::Lorem.sentence }
    description { Faker::Hipster.sentence }

    trait :without_measure do
      measures { [] }
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
  end
end

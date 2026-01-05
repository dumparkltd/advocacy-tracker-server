FactoryBot.define do
  factory :measuretype do
    sequence(:id) { |n| n + 100 } # start IDs at 101 to avoid STATEMENT_TYPE_ID
    title { Faker::Creature::Cat.registry }

    trait :parent_allowed do
      has_parent { true }
    end

    trait :parent_not_allowed do
      has_parent { false }
    end

    trait :statement do
      id { Measure::STATEMENT_TYPE_ID }
      title { "Statement" }
    end

    trait :not_a_statement do
      title { "Not a Statement" }
    end
  end
end

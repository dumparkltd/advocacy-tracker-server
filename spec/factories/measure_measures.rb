FactoryBot.define do
  factory :measure_measure do
    association :measure

    transient do
      shared_measuretype { measure.measuretype }
    end

    association :other_measure, factory: :measure, measuretype: -> { shared_measuretype }
  end
end

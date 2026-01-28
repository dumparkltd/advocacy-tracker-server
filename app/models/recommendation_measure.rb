class RecommendationMeasure < ApplicationRecord
  belongs_to :recommendation, inverse_of: :recommendation_measures
  belongs_to :measure, inverse_of: :recommendation_measures

  validates :measure_id, uniqueness: {scope: :recommendation_id}
  validates :recommendation_id, presence: true
  validates :measure_id, presence: true
end

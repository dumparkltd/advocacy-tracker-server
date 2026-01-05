class RecommendationCategory < ApplicationRecord
  belongs_to :recommendation
  belongs_to :category

  validates :category_id, uniqueness: {scope: :recommendation_id}
  validates :recommendation_id, presence: true
  validates :category_id, presence: true
end

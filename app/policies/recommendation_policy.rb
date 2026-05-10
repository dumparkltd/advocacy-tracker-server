# frozen_string_literal: true

class RecommendationPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :title,
      :draft,
      :accepted,
      :response,
      :reference,
      :description,
      :framework_id
    ]
  end
end

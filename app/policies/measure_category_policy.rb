# frozen_string_literal: true

class MeasureCategoryPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :category_id,
      :measure_id,
      :updated_by_id
    ]
  end

  def update?
    false
  end
end

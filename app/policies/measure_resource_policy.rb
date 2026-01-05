# frozen_string_literal: true

class MeasureResourcePolicy < ApplicationPolicy
  def permitted_attributes
    [
      :measure_id,
      :resource_id,
      :updated_by_id
    ]
  end

  def update?
    false
  end
end

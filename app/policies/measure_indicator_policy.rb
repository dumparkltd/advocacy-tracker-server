# frozen_string_literal: true

class MeasureIndicatorPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :measure_id,
      :indicator_id,
      :supportlevel_id,
      :updated_by_id
    ]
  end
end

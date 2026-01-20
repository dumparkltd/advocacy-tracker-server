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

  def destroy?
    # Override ApplicationPolicy - managers/coordinators can delete relationships
    @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")
  end
end

# frozen_string_literal: true

class MeasureMeasurePolicy < ApplicationPolicy
  def permitted_attributes
    [
      :created_by_id,
      :measure_id,
      :other_measure_id,
      :updated_by_id
    ]
  end

  def create?
    super && @record.can_be_changed_by?(@user)
  end

  def update?
    false
  end

  def destroy?
    # Override ApplicationPolicy - managers/coordinators can delete relationships
    # (unless the statement is blocked)
    return false unless @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")

    @record.can_be_changed_by?(@user)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

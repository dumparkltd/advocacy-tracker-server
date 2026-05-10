# frozen_string_literal: true

class ActorMeasurePolicy < ApplicationPolicy
  def permitted_attributes
    [
      :actor_id,
      :created_by_id,
      :date_end,
      :date_start,
      :measure_id,
      :updated_by_id,
      :value
    ]
  end

  def create?
    super && @record.can_be_changed_by?(@user)
  end

  def update?
    super && @record.can_be_changed_by?(@user)
  end

  def destroy?
    # Override ApplicationPolicy - managers/coordinators can delete relationships
    # (unless the statement is published)
    return false unless @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")

    @record.can_be_changed_by?(@user)
  end
end

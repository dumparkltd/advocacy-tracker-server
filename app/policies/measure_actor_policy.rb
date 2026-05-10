# frozen_string_literal: true

class MeasureActorPolicy < ApplicationPolicy
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
    @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")
  end
end

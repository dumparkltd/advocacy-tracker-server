# frozen_string_literal: true

class MeasureCategoryPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :category_id,
      :measure_id,
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
    # (unless the statement is published)
    return false unless @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")

    @record.can_be_changed_by?(@user)
  end
end

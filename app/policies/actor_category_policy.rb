# frozen_string_literal: true

class ActorCategoryPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :category_id,
      :actor_id,
      :updated_by_id
    ]
  end

  def destroy?
    # Override ApplicationPolicy - managers/coordinators can delete relationships
    @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")
  end
end

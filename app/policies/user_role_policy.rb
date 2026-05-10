# frozen_string_literal: true

class UserRolePolicy < ApplicationPolicy
  def update?
    false
  end

  def create?
    @user.role?("admin")
  end

  def destroy?
    @user.role?("admin")
  end

  def permitted_attributes
    [
      :user_id,
      :role_id
    ]
  end

  class Scope < Scope
    def resolve
      return super if @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator") || @user.role?("analyst")

      scope.where(user_id: @user.id)
    end
  end
end

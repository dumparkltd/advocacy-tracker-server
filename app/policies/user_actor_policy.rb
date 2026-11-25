# frozen_string_literal: true

class UserActorPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :actor_id,
      :created_by_id,
      :updated_by_id,
      :user_id
    ]
  end

  def update?
    false
  end

  def destroy?
    @user.role?("coordinator") || super
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

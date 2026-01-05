# frozen_string_literal: true

class DueDatePolicy < ApplicationPolicy
  def permitted_attributes
    [:due_date,
      :indicator_id,
      :draft
    ]
  end

  def show?
    super
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      return scope.all if @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")
      scope.none
    end
  end
end

class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    @record.id == @user.id || super
  end

  def create?
    @user.roles.none?
  end

  def edit?
    false
  end

  def update?
    @user.role?("admin") || @record.id == @user.id
  end

  def destroy?
    false
  end

  def permitted_attributes
    [
      :email,
      :password,
      :password_confirmation,
      :name,
      :updated_by_id
    ]
  end

  class Scope < Scope
    def resolve
      return scope.all if @user.role?("admin") || @user.role?("manager")

      scope.where(id: @user.id)
    end
  end
end

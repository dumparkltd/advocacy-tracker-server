# frozen_string_literal: true

class ActorCategoryPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :category_id,
      :actor_id,
      :updated_by_id
    ]
  end

  def update?
    false
  end
end

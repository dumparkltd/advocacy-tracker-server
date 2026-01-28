# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :member_id,
      :memberof_id,
      :updated_by_id
    ]
  end

  def update?
    false
  end
end

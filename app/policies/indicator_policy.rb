# frozen_string_literal: true

class IndicatorPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :code,
      :title,
      :description,
      :draft,
      :reference,
      :private,
      :updated_by_id,
      (@user.role?("admin") ? :is_archive : nil),
      (@user.role?("admin") ? :public_api : nil)
    ].compact
  end
end

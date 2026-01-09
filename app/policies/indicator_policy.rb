# frozen_string_literal: true

class IndicatorPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :code,
      :title,
      :description,
      :description_api,
      :draft,
      :reference,
      :private,
      :updated_by_id,
      :teaser_api,
      :annotation_api,
      :short_api,
      :code_api,
      (@user.role?("admin") ? :is_archive : nil),
      (@user.role?("admin") ? :public_api : nil)
    ].compact
  end
end

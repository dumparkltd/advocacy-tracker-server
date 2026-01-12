# frozen_string_literal: true

class IndicatorPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :code,
      :title,
      :description,
      # :description_api,
      :draft,
      :reference,
      :private,
      :updated_by_id,
      # :teaser_api,
      # :annotation_api,
      # :short_api,
      :code_api,
      # only for admins
      (@user.role?("admin") ? :is_archive : nil),
      # only for admins or coordinators
      (@user.role?("admin") || @user.role?("coordinator")  ? :public_api : nil)
    ].compact
  end
end

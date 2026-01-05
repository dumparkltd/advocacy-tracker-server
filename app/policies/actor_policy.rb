# frozen_string_literal: true

class ActorPolicy < ApplicationPolicy
  def permitted_attributes
    [
      :activity_summary,
      # actortype_id only on create
      (@record.new_record? ? :actortype_id : nil),
      :address,
      :code,
      :description,
      :draft,
      :email,
      :gdp,
      :manager_id,
      :parent_id,
      :phone,
      :population,
      :prefix,
      :private,
      :title,
      :url,
      :updated_by_id,
      # only for admins
      (@user.role?("admin") ? :is_archive : nil),
      (@user.role?("admin") ? :public_api : nil)
    ].compact
  end
end

# frozen_string_literal: true

class MeasurePolicy < ApplicationPolicy
  def permitted_attributes
    [
      :amount_comment,
      :amount,
      :code,
      :comment,
      :date_comment,
      :date_end,
      :date_start,
      :description,
      :draft,
      # measuretype_id only on create
      (@record.new_record? ? :measuretype_id : nil),
      :notifications,
      :outcome,
      :parent_id,
      :private,
      :status_comment,
      :target_comment,
      :target_date_comment,
      :target_date,
      :title,
      :url,
      :updated_by_id,
      # only for admins
      (@user.role?("admin") ? :is_archive : nil),
      (@user.role?("admin") ? :public_api : nil)
    ].compact
  end
end

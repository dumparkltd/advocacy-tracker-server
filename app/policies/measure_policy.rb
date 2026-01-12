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
      :quote_api,
      :source_api,
      (statement? ? :is_official : nil),
      # only for admins
      (@user.role?("admin") ? :is_archive : nil),
      # only for admins or coordinators
      ((@user.role?("admin") || @user.role?("coordinator")) && statement? ? :public_api : nil)
    ].compact
  end

  private

  def statement?
    @record.statement? || (@record.new_record? && @record.measuretype_id == Measure::STATEMENT_TYPE_ID)
  end
end

# frozen_string_literal: true

class ProgressReportPolicy < ApplicationPolicy
  def permitted_attributes
    [:indicator_id, :due_date_id, :title, :description, :document_url, :document_public, :draft,
      indicator_attributes: [:id, :title, :description, :draft],
      due_date_attributes: [:id, :due_date, :indicator_id, :draft]]
  end

  def create?
    super || @user.role?("admin") || @user.role?("manager") || @user.role?("coordinator")
  end

  def update?
    super
  end
end

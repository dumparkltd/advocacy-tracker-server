class ResourcePolicy < ApplicationPolicy
  def permitted_attributes
    [
      :access_date,
      :description,
      :draft,
      :private,
      :publication_date,
      :status,
      :title,
      :resourcetype_id,
      :url,
      :updated_by_id,
      (:is_archive if @user.role?("admin"))
    ].compact
  end
end

# frozen_string_literal: true

class User < VersionedRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User
  has_paper_trail ignore: [:tokens, :updated_at]

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :managed_categories, foreign_key: :manager_id, class_name: "Category"
  has_many :managed_indicators, foreign_key: :manager_id, class_name: "Indicator"
  has_many :user_categories, dependent: :destroy
  has_many :categories, through: :user_categories
  has_many :bookmarks, dependent: :destroy
  has_many :user_actors, dependent: :destroy
  has_many :actors, through: :user_actors
  has_many :user_measures, dependent: :destroy
  has_many :measures, through: :user_measures

  belongs_to :relationship_updated_by, class_name: "User", required: false

  validates :email, presence: true
  validates :name, presence: true

  def role?(role)
    roles.where(name: role).any?
  end
end

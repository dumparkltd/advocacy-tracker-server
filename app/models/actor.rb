class Actor < VersionedRecord
  # Type constants matching seed data
  COUNTRY_TYPE_ID = 1
  GROUP_TYPE_ID = 5

  belongs_to :actortype, required: true
  belongs_to :manager, class_name: "User", required: false
  belongs_to :parent, class_name: "Actor", required: false

  has_many :memberships, foreign_key: :memberof_id, dependent: :destroy
  has_many :members, class_name: "Actor", through: :memberships, source: :member

  has_many :membershipsof, class_name: "Membership", foreign_key: :member_id, dependent: :destroy
  has_many :membersof, class_name: "Actor", through: :membershipsof, source: :memberof

  has_many :actor_categories, dependent: :destroy
  has_many :categories, through: :actor_categories

  has_many :actor_measures, dependent: :destroy
  has_many :active_measures, through: :actor_measures

  has_many :measure_actors, dependent: :destroy
  has_many :passive_measures, through: :measure_actors

  has_many :user_actors, dependent: :destroy
  has_many :users, through: :user_actors

  belongs_to :relationship_updated_by, class_name: "User", required: false

  # Make type immutable after creation
  attr_readonly :actortype_id

  # Scope - only public countries
  scope :public_countries, -> {
    where(
      public_api: true,
      actortype_id: COUNTRY_TYPE_ID,
      is_archive: false,
      private: false,
      draft: false
    )
  }

  # Validations
  validates :title, presence: true
  validate :different_parent, :not_own_descendant
  validate :public_api_only_for_countries
  validate :public_api_requires_clean_state
  validate :is_archive_requires_unpublished
  validate :private_requires_unpublished
  validate :draft_requires_unpublished

  def publicly_accessible?
    public_api? && country? && !is_archive? && !private? && !draft?
  end

  def country?
    actortype_id == COUNTRY_TYPE_ID
  end

  private

  def different_parent
    if parent_id && parent_id == id
      errors.add(:parent_id, "can't be the same as id")
    end
  end

  def not_own_descendant
    measure_parent = self
    while (measure_parent = measure_parent.parent)
      errors.add(:parent_id, "can't be its own descendant") if measure_parent.id == id
    end
  end

  def public_api_only_for_countries
    if public_api? && !country?
      errors.add(:public_api, 'Only countries can be published to GPN (actortype_id = 1)')
    end
  end

  def public_api_requires_clean_state
    if public_api?
      errors.add(:public_api, 'Cannot be published to GPN when record is archived') if is_archive?
      errors.add(:public_api, 'Cannot be published to GPN when record is confidential') if private?
      errors.add(:public_api, 'Cannot be published to GPN when record is in draft') if draft?
    end
  end

  def is_archive_requires_unpublished
    if is_archive? && public_api?
      errors.add(:is_archive, 'Record cannot be archived when published to GPN')
    end
  end

  def private_requires_unpublished
    if private? && public_api?
      errors.add(:private, 'Record cannot be marked confidential when published to GPN')
    end
  end

  def draft_requires_unpublished
    if draft? && public_api?
      errors.add(:draft, 'Record cannot be marked as draft when published to GPN')
    end
  end
end

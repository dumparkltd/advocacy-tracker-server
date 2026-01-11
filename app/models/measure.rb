# frozen_string_literal: true

class Measure < VersionedRecord
  # Type constants matching seed data
  STATEMENT_TYPE_ID = 1
  EVENT_TYPE_ID = 2

  has_many :recommendation_measures, inverse_of: :measure, dependent: :destroy
  has_many :measure_categories, inverse_of: :measure, dependent: :destroy
  has_many :measure_indicators, inverse_of: :measure, dependent: :destroy

  has_many :actor_measures, dependent: :destroy
  has_many :active_measures, through: :actor_measures

  has_many :measure_actors, dependent: :destroy
  has_many :passive_measures, through: :measure_actors

  has_many :measure_measures, dependent: :destroy
  has_many :measures, through: :measure_measures
  has_many :other_measure_measures, class_name: "MeasureMeasure", dependent: :destroy, foreign_key: :other_measure_id
  has_many :parent_measures, through: :other_measure_measures, source: :other_measure

  has_many :measure_resources, dependent: :destroy
  has_many :resources, through: :measure_resources

  has_many :recommendations, through: :recommendation_measures, inverse_of: :measures
  has_many :categories, through: :measure_categories, inverse_of: :measures
  has_many :indicators, through: :measure_indicators, inverse_of: :measures
  has_many :due_dates, through: :indicators
  has_many :progress_reports, through: :indicators

  has_many :user_measures, dependent: :destroy
  has_many :users, through: :user_measures

  belongs_to :measuretype, required: true
  belongs_to :parent, class_name: "Measure", required: false

  belongs_to :relationship_updated_by, class_name: "User", required: false

  # Make type immutable after creation
  attr_readonly :measuretype_id

  # Scope - only public statements
  scope :public_statements, -> {
    where(
      public_api: true,
      measuretype_id: STATEMENT_TYPE_ID,
      is_official: true,
      is_archive: false,
      private: false,
      draft: false
    )
  }

  validates :title, presence: true
  validates :measuretype_id, presence: true
  validate(
    :different_parent,
    :not_own_descendant,
    :parent_id_allowed_by_measuretype
  )
  validate :public_api_only_for_statements
  validate :public_api_requires_clean_state
  validate :is_archive_requires_unpublished
  validate :is_not_official_requires_unpublished
  validate :private_requires_unpublished
  validate :draft_requires_unpublished

  def self.notifiable_attribute_names
    Measure.attribute_names - %w[updated_at]
  end

  def notifiable_user_measures(user_id:)
    user_measures.where.not(user_id: user_id)
  end

  after_commit :queue_task_updated_notifications!,
    on: :update,
    if: [:task?, :relationship_updated?]

  def queue_task_updated_notifications!(user_id: ::PaperTrail.request.whodunnit)
    return unless notify?

    delete_existing_task_notifications!(user_id:)

    notifiable_user_measures(user_id:).each do |user_measure|
      queue_task_updated_notification!(
        user_id: user_measure.user_id,
        measure_id: user_measure.measure_id,
        delete_existing: false # this is already handled above by delete_existing_task_notifications!
      )
    end
  end

  def queue_task_updated_notification!(user_id:, measure_id:, delete_existing: true)
    return unless notify?

    delete_existing_task_notifications!(user_id:) if delete_existing

    TaskNotificationJob.perform_in(ENV.fetch("TASK_NOTIFICATION_DELAY", 20).to_i.seconds, user_id, measure_id)
  end

  def task?
    measuretype&.notifications?
  end

  def publicly_accessible?
    public_api? && is_official? && statement? && !is_archive? && !private? && !draft?
  end

  def statement?
    measuretype_id == STATEMENT_TYPE_ID
  end

  def event?
    measuretype_id == EVENT_TYPE_ID
  end

  private

  def delete_existing_task_notifications!(user_id:)
    user_measure_ids = notifiable_user_measures(user_id:).pluck(:id)

    Sidekiq::ScheduledSet.new
      .select { |job| user_measure_ids.include?(job.args.first) && job.klass == "TaskNotificationJob" }
      .map(&:delete)
  end

  def different_parent
    if parent_id && parent_id == id
      errors.add(:parent_id, "can't be the same as id")
    end
  end

  def notify?
    task? &&
      !is_archive? &&
      notifications? &&
      (!draft? && !saved_change_to_attribute?(:draft)) &&
      (saved_changes.keys & Measure.notifiable_attribute_names).any?
  end

  def not_own_descendant
    measure_parent = self
    while (measure_parent = measure_parent.parent)
      errors.add(:parent_id, "can't be its own descendant") if measure_parent.id == id
    end
  end

  def parent_id_allowed_by_measuretype
    if parent_id && !parent.measuretype&.has_parent
      errors.add(:parent_id, "is not allowed for this measuretype")
    end
  end

  def relationship_updated?
    saved_change_to_attribute?(:relationship_updated_at)
  end

  def public_api_only_for_statements
    if public_api? && !statement?
      errors.add(:public_api, 'Only statements can be published to GPN (measuretype_id = 1)')
    end
  end

  def public_api_requires_clean_state
    if public_api?
      errors.add(:public_api, 'Cannot be published to GPN when record is archived') if is_archive?
      errors.add(:public_api, 'Cannot be published to GPN when record is confidential') if private?
      errors.add(:public_api, 'Cannot be published to GPN when record is in draft') if draft?
      errors.add(:public_api, 'Cannot be published to GPN when record is not official') if !is_official?
    end
  end

  def is_archive_requires_unpublished
    if is_archive? && public_api?
      errors.add(:is_archive, 'Record cannot be archived when published to GPN')
    end
  end

  def is_not_official_requires_unpublished
    if !is_official? && public_api?
      errors.add(:is_official, 'Record cannot be made not official when published to GPN')
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

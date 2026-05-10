class Indicator < VersionedRecord
  validates :title, presence: true
  validates :end_date, presence: true, if: :repeat?
  validates :frequency_months, presence: true, if: :repeat?
  validate :end_date_after_start_date, if: :end_date?

  after_create :build_due_dates
  after_update :regenerate_due_dates

  has_many :measure_indicators, inverse_of: :indicator, dependent: :destroy
  has_many :recommendation_indicators, inverse_of: :indicator, dependent: :destroy
  has_many :recommendations, through: :recommendation_indicators
  has_many :progress_reports
  has_many :due_dates
  has_many :measures, through: :measure_indicators, inverse_of: :indicators
  has_many :categories, through: :measures
  has_many :recommendations, through: :measures
  has_many :children, class_name: 'Indicator', foreign_key: 'parent_id', dependent: :nullify

  # not sure we need this?
  # has_many :direct_recommendations, through: :indicators_recommendations, source: :recommendation

  belongs_to :manager, class_name: "User", foreign_key: :manager_id, required: false
  belongs_to :relationship_updated_by, class_name: "User", required: false
  belongs_to :parent, class_name: 'Indicator', optional: true

  scope :public_topics, -> {
    where(
      public_api: true,
      is_archive: false,
      private: false,
      draft: false
    )
  }

  # Scopes
  scope :root_indicators, -> { where(parent_id: nil) }
  scope :child_indicators, -> { where.not(parent_id: nil) }
  scope :parent_indicators, -> { where(id: select(:parent_id).distinct) }

  # Validations
  validate :public_api_requires_clean_state
  validate :is_archive_requires_unpublished
  validate :private_requires_unpublished
  validate :draft_requires_unpublished
  validate :different_parent
  validate :no_grandparent

  # Method to check if record is public
  def publicly_accessible?
    public_api? && !is_archive? && !private? && !draft?
  end

  private

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

  def end_date_after_start_date
    if start_date > end_date
      errors.add(:end_date, "must be after start_date")
    end
  end

  def different_parent
    if parent_id.present? && parent_id == id
      errors.add(:parent_id, "cannot reference itself")
    end
  end

  def no_grandparent
    if parent_id.present?
      parent_indicator = Indicator.find_by(id: parent_id)
      if parent_indicator&.parent_id.present?
        errors.add(:parent_id, "cannot have a grandparent (maximum 2 levels allowed)")
      end
    end
  end


  def build_due_dates
    if repeat
      date_iterator = start_date
      while date_iterator <= end_date
        due_dates.find_or_create_by!(due_date: date_iterator)
        date_iterator += frequency_months.months
      end
    elsif start_date # No repeating
      due_dates.find_or_create_by!(due_date: start_date)
    end
  end

  def regenerate_due_dates
    return unless saved_change_to_start_date? || saved_change_to_end_date? || saved_change_to_frequency_months? || saved_change_to_repeat?
    due_dates.future_with_no_progress_reports.destroy_all
    build_due_dates
    true
  end
end

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

  # not sure we need this?
  # has_many :direct_recommendations, through: :indicators_recommendations, source: :recommendation

  belongs_to :manager, class_name: "User", foreign_key: :manager_id, required: false
  belongs_to :relationship_updated_by, class_name: "User", required: false

  # Validations
  validate :public_api_requires_clean_state
  validate :is_archive_requires_unpublished
  validate :private_requires_unpublished
  validate :draft_requires_unpublished

  # Method to check if record is public
  def publicly_accessible?
    public_api? && !is_archive? && !private? && !draft?
  end

  private

  def public_api_requires_clean_state
    if public_api?
      errors.add(:public_api, 'and is_archive cannot both be true') if is_archive?
      errors.add(:public_api, 'and private cannot both be true') if private?
      errors.add(:public_api, 'and draft cannot both be true') if draft?
    end
  end

  def is_archive_requires_unpublished
    if is_archive? && public_api?
      errors.add(:is_archive, 'and public_api cannot both be true')
    end
  end

  def private_requires_unpublished
    if private? && public_api?
      errors.add(:private, 'and public_api cannot both be true')
    end
  end

  def draft_requires_unpublished
    if draft? && public_api?
      errors.add(:draft, 'and public_api cannot both be true')
    end
  end

  def end_date_after_start_date
    if start_date > end_date
      errors.add(:end_date, "must be after start_date")
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

class MeasureIndicator < ApplicationRecord
  belongs_to :measure
  belongs_to :indicator

  validates :measure_id, uniqueness: {scope: :indicator_id}
  validates :measure_id, presence: true
  validates :indicator_id, presence: true

  after_commit :set_relationship_updated, on: [:create, :update, :destroy]

  scope :public_api, -> {
    joins(:measure, :indicator)
      .merge(Measure.public_statements)
      .where(indicators: { public_api: true, is_archive: false, private: false, draft: false })
  }

  def can_be_changed_by?(user)
    # returns false if measure doesn't exist or doesn't allow change
    measure&.can_change_relationships_by?(user)
  end

  def can_be_changed_by?(user)
    # returns false if measure doesn't exist or doesn't allow change
    measure&.can_change_relationships_by?(user)
  end

  private

  def set_relationship_updated
    if measure && !measure.destroyed?
      measure.update_attribute(:relationship_updated_at, Time.zone.now)
      measure.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end

    if indicator && !indicator.destroyed?
      indicator.update_attribute(:relationship_updated_at, Time.zone.now)
      indicator.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end
  end
end

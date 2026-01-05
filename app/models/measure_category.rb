class MeasureCategory < VersionedRecord
  belongs_to :measure
  belongs_to :category

  validates :category_id, uniqueness: {scope: :measure_id}
  validates :measure_id, presence: true
  validates :category_id, presence: true

  validate :category_taxonomy_enabled_for_measuretype

  after_commit :set_relationship_updated, on: [:create, :update, :destroy]

  private

  def category_taxonomy_enabled_for_measuretype
    unless category&.taxonomy&.measuretype_ids&.include?(measure&.measuretype_id)
      errors.add(:measure_id, "must have the category's taxonomy enabled for its measuretype")
    end
  end

  def set_relationship_updated
    if measure && !measure.destroyed?
      measure.update_attribute(:relationship_updated_at, Time.zone.now)
      measure.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end
  end
end

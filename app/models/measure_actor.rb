class MeasureActor < VersionedRecord
  belongs_to :actor, required: true
  belongs_to :measure, required: true

  validate :actor_actortype_is_target, :measure_measuretype_has_target

  after_commit :set_relationship_updated, on: [:create, :update, :destroy]

  def can_be_changed_by?(user)
    # returns false if measure doesn't exist or doesn't allow change
    measure&.can_change_relationships_by?(user)
  end

  private

  def actor_actortype_is_target
    errors.add(:actor, "actor's actortype is not target") unless actor&.actortype&.is_target
  end

  def measure_measuretype_has_target
    errors.add(:measure, "measure's measuretype can't have target") unless measure&.measuretype&.has_target
  end

  def set_relationship_updated
    if actor && !actor.destroyed?
      actor.update_attribute(:relationship_updated_at, Time.zone.now)
      actor.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end

    if measure && !measure.destroyed?
      measure.update_attribute(:relationship_updated_at, Time.zone.now)
      measure.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end
  end
end

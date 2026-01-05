class ActorMeasure < VersionedRecord
  belongs_to :actor, required: true
  belongs_to :measure, required: true

  validate :actor_actortype_is_active
  after_commit :set_relationship_updated, on: [:create, :update, :destroy]

  scope :public_api, -> {
    joins(:actor, :measure)
      .merge(Actor.public_countries)
      .merge(Measure.public_statements)
  }

  def publicly_accessible?
    actor&.publicly_accessible? && measure&.publicly_accessible?
  end

  private

  def actor_actortype_is_active
    errors.add(:actor, "actor's actortype is not active") unless actor&.actortype&.is_active
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

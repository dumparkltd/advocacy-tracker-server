class ActorCategory < VersionedRecord
  belongs_to :actor, required: true
  belongs_to :category, required: true

  validates :actor_id, presence: true
  validates :category_id, presence: true, uniqueness: {scope: :actor_id}
  validate :category_taxonomy_enabled_for_actortype

  after_commit :set_relationship_updated, on: [:create, :update, :destroy]

  private

  def category_taxonomy_enabled_for_actortype
    unless category&.taxonomy&.actortype_ids&.include?(actor&.actortype_id)
      errors.add(:category, "must have its taxonomy enabled for actor's actortype")
    end
  end

  def set_relationship_updated
    if actor && !actor.destroyed?
      actor.update_attribute(:relationship_updated_at, Time.zone.now)
      actor.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end
  end
end

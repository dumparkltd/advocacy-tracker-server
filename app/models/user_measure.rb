class UserMeasure < VersionedRecord
  belongs_to :user
  belongs_to :measure

  validates :user_id, uniqueness: {scope: :measure_id}
  validates :user_id, presence: true
  validates :measure_id, presence: true

  def notify?
    measure.notifications?
  end

  after_commit :set_relationship_created, on: [:create]
  after_commit :set_relationship_updated, on: [:update, :destroy]

  def can_be_changed_by?(user)
    # returns false if measure doesn't exist or doesn't allow change
    measure&.can_change_relationships_by?(user)
  end

  private

  def set_relationship_created
    if user && !user.destroyed?
      user.update_column(:relationship_updated_at, Time.zone.now)
      user.update_column(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end

    if measure && !measure.destroyed?
      measure.update_column(:relationship_updated_at, Time.zone.now)
      measure.update_column(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)

      if measure.task?
        self.class
          .where(measure_id: measure_id)
          .where.not(user_id: [user_id, ::PaperTrail.request.whodunnit])
          .find_each do |other_user_measure|
            measure.queue_task_updated_notification!(
              user_id: other_user_measure.user_id,
              measure_id: other_user_measure.measure_id
            )
          end
      end
    end
  end

  def set_relationship_updated
    if measure && !measure.destroyed?
      measure.update_attribute(:relationship_updated_at, Time.zone.now)
      measure.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end

    if user && !user.destroyed?
      user.update_attribute(:relationship_updated_at, Time.zone.now)
      user.update_attribute(:relationship_updated_by_id, ::PaperTrail.request.whodunnit)
    end
  end
end

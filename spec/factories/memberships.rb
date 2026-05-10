FactoryBot.define do
  factory :membership do
    # transient attributes allow overriding actortypes
    transient do
      member_type { nil }
      memberof_type { nil }
    end

    member do
      if member_type
        create(:actor, actortype: member_type)
      else
        create(:actor)
      end
    end

    memberof do
      if memberof_type
        create(:actor, actortype: memberof_type)
      else
        create(:actor)
      end
    end
  end
end

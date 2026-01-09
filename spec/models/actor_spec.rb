require "rails_helper"

RSpec.describe Actor, type: :model do
  let!(:country_actortype) { FactoryBot.create(:actortype, :country) }
  let!(:not_country_actortype) { FactoryBot.create(:actortype, :not_a_country) }

  it { is_expected.to validate_presence_of :title }
  it { is_expected.to belong_to :actortype }

  it "is expected to default private to false" do
    expect(subject.private).to eq(false)
  end

  it "is expected to default draft to true" do
    expect(subject.draft).to eq(true)
  end

  it "is expected to cascade destroy dependent relationships" do
    actor = FactoryBot.create(:actor)

    taxonomy = FactoryBot.create(:taxonomy, actortype_ids: [actor.actortype_id])
    FactoryBot.create(:actor_category, actor: actor, category: FactoryBot.create(:category, taxonomy: taxonomy))
    FactoryBot.create(:actor_measure, actor: actor)
    FactoryBot.create(:measure_actor, actor: actor)
    FactoryBot.create(:membership, member: actor, memberof: FactoryBot.create(:actor, actortype: FactoryBot.create(:actortype, has_members: true)))
    FactoryBot.create(:user_actor, actor: actor)

    expect { actor.destroy }.to change {
      [Actor.count, ActorCategory.count, ActorMeasure.count, MeasureActor.count, Membership.count, UserActor.count]
    }.from([2, 1, 1, 1, 1, 1]).to([1, 0, 0, 0, 0, 0])
  end

  context "parent_id" do
    subject { FactoryBot.create(:actor) }

    it "can't be the record's ID" do
      subject.parent_id = subject.id
      expect(subject).to be_invalid
      expect(subject.errors[:parent_id]).to(include("can't be the same as id"))
    end

    it "can't be its own descendant" do
      child = FactoryBot.create(:actor, parent_id: subject.id)
      expect(child).to be_valid
      subject.parent_id = child.id
      expect(subject).to be_invalid
      expect(subject.errors[:parent_id]).to include("can't be its own descendant")
    end
  end

  describe 'constants' do
    it 'defines COUNTRY_TYPE_ID' do
      expect(Actor::COUNTRY_TYPE_ID).to eq(1)
    end
  end

  describe 'type immutability' do
    it 'allows setting actortype_id on creation' do
      expect {
        actor = FactoryBot.create(:actor, actortype: country_actortype)
        expect(actor.actortype_id).to eq(Actor::COUNTRY_TYPE_ID)
      }.to change(Actor, :count).by(1)
    end

    it 'prevents changing actortype_id after creation' do
      actor = FactoryBot.create(:actor, actortype: country_actortype)
      expect {
        actor.update!(actortype_id: 2)
      }.to raise_error(ActiveRecord::ReadonlyAttributeError, /actortype_id/)

      expect(actor.reload.actortype_id).to eq(Actor::COUNTRY_TYPE_ID)
    end
  end

  describe 'validations' do
    describe 'public_api only for countries' do
      it 'allows public_api for countries when state is clean' do
        actor = FactoryBot.build(:actor, actortype: country_actortype, public_api: true,
                     is_archive: false, private: false, draft: false)
        expect(actor).to be_valid
      end

      it 'rejects public_api for non-countries' do
        actor = FactoryBot.build(:actor, actortype: not_country_actortype, public_api: true,
                     is_archive: false, private: false, draft: false)
        expect(actor).not_to be_valid
      end
    end

    describe 'public_api state requirements' do
      it 'rejects public_api when archived' do
        actor = FactoryBot.build(:actor, actortype: country_actortype,
                     public_api: true, is_archive: true, private: false, draft: false)
        expect(actor).not_to be_valid
      end

      it 'rejects public_api when confidential' do
        actor = FactoryBot.build(:actor, actortype: country_actortype,
                     public_api: true, is_archive: false, private: true, draft: false)
        expect(actor).not_to be_valid
      end

      it 'rejects public_api when draft' do
        actor = FactoryBot.build(:actor, actortype: country_actortype,
                     public_api: true, is_archive: false, private: false, draft: true)
        expect(actor).not_to be_valid
      end
    end

    describe 'bidirectional validation errors' do
      it 'shows error on is_archive when trying to archive public country' do
        actor = FactoryBot.build(:actor, actortype: country_actortype,
                     public_api: true, is_archive: true, private: false, draft: false)
        expect(actor).not_to be_valid
      end

      it 'shows error on private when trying to make public country confidential' do
        actor = FactoryBot.build(:actor, actortype: country_actortype,
                     public_api: true, is_archive: false, private: true, draft: false)
        expect(actor).not_to be_valid
      end

      it 'shows error on draft when trying to draft public country' do
        actor = FactoryBot.build(:actor, actortype: country_actortype,
                     public_api: true, is_archive: false, private: false, draft: true)
        expect(actor).not_to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:public_country) do
      FactoryBot.create(:actor, public_api: true, actortype: country_actortype,
             is_archive: false, private: false, draft: false)
    end
    let!(:private_country) do
      FactoryBot.create(:actor, public_api: false, actortype: country_actortype,
             is_archive: false, private: false, draft: false)
    end
    let!(:public_non_country) do
      FactoryBot.create(:actor, public_api: false, actortype: not_country_actortype,
             is_archive: false, private: false, draft: false)
    end
    let!(:archived_country) do
      FactoryBot.create(:actor, public_api: false, actortype: country_actortype,
             is_archive: true, private: false, draft: false)
    end
    let!(:draft_country) do
      FactoryBot.create(:actor, public_api: false, actortype: country_actortype,
             is_archive: false, private: false, draft: true)
    end

    describe '.public_countries' do
      it 'returns only public countries with clean state' do
        result = Actor.public_countries
        expect(result).to include(public_country)
        expect(result).not_to include(private_country)
        expect(result).not_to include(public_non_country)
        expect(result).not_to include(archived_country)
        expect(result).not_to include(draft_country)
      end
    end
  end

  describe '#country?' do
    it 'returns true for countries' do
      actor = FactoryBot.build(:actor, actortype: country_actortype)
      expect(actor.country?).to eq(true)
    end

    it 'returns false for non-countries' do
      actor = FactoryBot.build(:actor, actortype: not_country_actortype)
      expect(actor.country?).to eq(false)
    end
  end

  describe '#publicly_accessible?' do
    it 'returns true when all conditions met' do
      actor = FactoryBot.build(:actor, public_api: true, actortype: country_actortype,
                   is_archive: false, private: false, draft: false)
      expect(actor.publicly_accessible?).to eq(true)
    end

    it 'returns false when not a country' do
      actor = FactoryBot.build(:actor, public_api: true, actortype: not_country_actortype,
                   is_archive: false, private: false, draft: false)
      expect(actor.publicly_accessible?).to eq(false)
    end

    it 'returns false when not public_api' do
      actor = FactoryBot.build(:actor, public_api: false, actortype: country_actortype,
                   is_archive: false, private: false, draft: false)
      expect(actor.publicly_accessible?).to eq(false)
    end

    it 'returns false when archived' do
      actor = FactoryBot.build(:actor, public_api: true, actortype: country_actortype,
                   is_archive: true, private: false, draft: false)
      expect(actor.publicly_accessible?).to eq(false)
    end

    it 'returns false when confidential' do
      actor = FactoryBot.build(:actor, public_api: true, actortype: country_actortype,
                   is_archive: false, private: true, draft: false)
      expect(actor.publicly_accessible?).to eq(false)
    end

    it 'returns false when draft' do
      actor = FactoryBot.build(:actor, public_api: true, actortype: country_actortype,
                   is_archive: false, private: false, draft: true)
      expect(actor.publicly_accessible?).to eq(false)
    end
  end

end

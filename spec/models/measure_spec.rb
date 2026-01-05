require "rails_helper"

RSpec.describe Measure, type: :model do
  let!(:statement_measuretype) { FactoryBot.create(:measuretype, :statement) }
  let!(:not_statement_measuretype) { FactoryBot.create(:measuretype, :not_a_statement) }
  let!(:with_parent_measuretype) { FactoryBot.create(:measuretype, :parent_allowed) }
  let!(:not_with_parent_measuretype) { FactoryBot.create(:measuretype, :parent_not_allowed) }
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to have_many :categories }
  it { is_expected.to have_many :indicators }

  it "is expected to default private to false" do
    expect(subject.private).to eq(false)
  end

  it "is expected to default notifications to true" do
    expect(subject.notifications).to eq(true)
  end

  context "parent_id" do
    subject do
      described_class.create(
        measuretype: with_parent_measuretype,
        title: "test"
      )
    end

    it "can be set to a measure with :measuretype.has_parent = true" do
      subject.parent_id = described_class.create(
        measuretype: with_parent_measuretype,
        title: "no parent"
      ).id
      expect(subject).to be_valid
    end

    it "can't be the record's ID" do
      subject.parent_id = subject.id
      expect(subject).to be_invalid
      expect(subject.errors[:parent_id]).to(include("can't be the same as id"))
    end

    it "can't be set to a measure with :measuretype.has_parent = false" do
      subject.parent_id = described_class.create(
        measuretype: not_with_parent_measuretype,
        title: "no parent"
      ).id
      expect(subject).to be_invalid
      expect(subject.errors[:parent_id]).to(include("is not allowed for this measuretype"))
    end

    it "can't be its own descendant" do
      child = described_class.create(
        measuretype: with_parent_measuretype,
        parent_id: subject.id,
        title: "immediate child"
      )
      expect(child).to be_valid
      subject.parent_id = child.id
      expect(subject).to be_invalid
      expect(subject.errors[:parent_id]).to include("can't be its own descendant")
    end

    it "is expected to cascade destroy dependent relationships" do
      measure = FactoryBot.create(:measure, measuretype: statement_measuretype)

      taxonomy = FactoryBot.create(:taxonomy, measuretype_ids: [statement_measuretype.id])
      FactoryBot.create(:measure_category, measure: measure, category: FactoryBot.create(:category, taxonomy: taxonomy))
      FactoryBot.create(:measure_indicator, measure: measure)
      FactoryBot.create(:actor_measure, measure: measure)
      FactoryBot.create(:measure_actor, measure: measure)

      FactoryBot.create(
        :measure_measure,
        measure: measure,
        other_measure: FactoryBot.create(:measure, measuretype: measure.measuretype)
      )

      FactoryBot.create(:measure_resource, measure: measure)
      FactoryBot.create(:user_measure, measure: measure)

      expect { measure.destroy }.to change {
        [
          Measure.count,
          MeasureCategory.count,
          MeasureIndicator.count,
          MeasureMeasure.count,
          MeasureResource.count,
          ActorMeasure.count,
          MeasureActor.count,
          UserMeasure.count
        ]
      }.from([2, 1, 1, 1, 1, 1, 1, 1]).to([1, 0, 0, 0, 0, 0, 0, 0])
    end

    it "is expected to cascade destroy other_measure_measures relationships" do
      measure_measure = FactoryBot.create(
        :measure_measure,
        measure: FactoryBot.create(:measure, measuretype: statement_measuretype),
        other_measure: FactoryBot.create(:measure, measuretype: statement_measuretype)
      )

      expect { measure_measure.other_measure.destroy }.to change {
        Measure.count
      }.from(2).to(1)
    end
  end

  context "notifications" do
    subject { FactoryBot.create(:measure, :not_draft, notifications: true, measuretype: statement_measuretype) }
    let!(:user) { FactoryBot.create(:user) }
    let(:user_id) { user.id }
    let!(:user_measure) { FactoryBot.create(:user_measure, measure: subject) }

    before { allow(::PaperTrail.request).to receive(:whodunnit).and_return(user_id) }

    context "for non 'task' measures" do
      before { allow(subject.measuretype).to receive(:notifications?).and_return(false) }

      it "won't send when relationship_updated_at changes" do
        expect { subject.touch(:relationship_updated_at) }
          .not_to change { ActionMailer::Base.deliveries.count }.from(0)
      end
    end

    context "for 'task' measures" do
      before { allow(subject.measuretype).to receive(:notifications?).and_return(true) }

      context "when the current user owns the task" do
        let(:user_id) { user_measure.user_id }

        it "won't queue notifications when relationship_updated_at changes" do
          expect(TaskNotificationJob).not_to receive(:perform_in)

          subject.touch(:relationship_updated_at)
        end
      end

      context "when the current user doesn't own the task" do
        let(:user_id) { FactoryBot.create(:user).id }

        it "will queue notifications when relationship_updated_at changes" do
          expect(TaskNotificationJob).to receive(:perform_in).with(ENV.fetch("TASK_NOTIFICATION_DELAY", 20).to_i.seconds, user_measure.user_id, user_measure.measure_id)

          subject.touch(:relationship_updated_at)
        end
      end

      it "won't queue notifications when relationship_updated_at doesn't change" do
        expect(subject).not_to receive(:queue_task_updated_notifications!)

        subject.update(title: "testing 12345")
      end
    end
  end

  describe 'constants' do
    it 'defines STATEMENT_TYPE_ID' do
      expect(Measure::STATEMENT_TYPE_ID).to eq(1)
    end
  end

  describe 'type immutability' do
    it 'allows setting measuretype_id on creation' do
      expect {
        measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
        expect(measure.measuretype_id).to eq(Measure::STATEMENT_TYPE_ID)
      }.to change(Measure, :count).by(1)
    end

    it 'prevents changing measuretype_id after creation' do
      measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
      expect {
        measure.update!(measuretype_id: 2)
      }.to raise_error(ActiveRecord::ReadonlyAttributeError, /measuretype_id/)

      expect(measure.reload.measuretype_id).to eq(Measure::STATEMENT_TYPE_ID)
    end
  end

  describe 'validations' do
    describe 'public_api only for statements' do
      it 'allows public_api for statements when state is clean' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype, public_api: true,
                       is_archive: false, private: false, draft: false)
        expect(measure).to be_valid
      end

      it 'rejects public_api for non-statements' do
        measure = FactoryBot.build(:measure, measuretype: not_statement_measuretype, public_api: true,
                       is_archive: false, private: false, draft: false)
        expect(measure).not_to be_valid
        expect(measure.errors[:public_api]).to include('can only be set to true for statements (measuretype_id = 1)')
      end
    end

    describe 'public_api state requirements' do
      it 'rejects public_api when archived' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype,
                       public_api: true, is_archive: true, private: false, draft: false)
        expect(measure).not_to be_valid
        expect(measure.errors[:public_api]).to include('and is_archive cannot both be true')
      end

      it 'rejects public_api when confidential' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype,
                       public_api: true, is_archive: false, private: true, draft: false)
        expect(measure).not_to be_valid
        expect(measure.errors[:public_api]).to include('and private cannot both be true')
      end

      it 'rejects public_api when draft' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype,
                       public_api: true, is_archive: false, private: false, draft: true)
        expect(measure).not_to be_valid
        expect(measure.errors[:public_api]).to include('and draft cannot both be true')
      end
    end

    describe 'bidirectional validation errors' do
      it 'shows error on is_archive when trying to archive public statement' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype,
                       public_api: true, is_archive: true, private: false, draft: false)
        expect(measure).not_to be_valid
        expect(measure.errors[:is_archive]).to include('and public_api cannot both be true')
      end

      it 'shows error on private when trying to make public statement confidential' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype,
                       public_api: true, is_archive: false, private: true, draft: false)
        expect(measure).not_to be_valid
        expect(measure.errors[:private]).to include('and public_api cannot both be true')
      end

      it 'shows error on draft when trying to draft public statement' do
        measure = FactoryBot.build(:measure, measuretype: statement_measuretype,
                       public_api: true, is_archive: false, private: false, draft: true)
        expect(measure).not_to be_valid
        expect(measure.errors[:draft]).to include('and public_api cannot both be true')
      end
    end
  end

  describe 'scopes' do
    let!(:public_statement) do
      FactoryBot.create(:measure, public_api: true, measuretype: statement_measuretype,
             is_archive: false, private: false, draft: false)
    end
    let!(:private_statement) do
      FactoryBot.create(:measure, public_api: false, measuretype: statement_measuretype,
             is_archive: false, private: false, draft: false)
    end
    let!(:public_non_statement) do
      FactoryBot.create(:measure, public_api: false, measuretype: not_statement_measuretype,
             is_archive: false, private: false, draft: false)
    end
    let!(:archived_statement) do
      FactoryBot.create(:measure, public_api: false, measuretype: statement_measuretype,
             is_archive: true, private: false, draft: false)
    end
    let!(:draft_statement) do
      FactoryBot.create(:measure, public_api: false, measuretype: statement_measuretype,
             is_archive: false, private: false, draft: true)
    end

    describe '.public_statements' do
      it 'returns only public statements with clean state' do
        result = Measure.public_statements
        expect(result).to include(public_statement)
        expect(result).not_to include(private_statement)
        expect(result).not_to include(public_non_statement)
        expect(result).not_to include(archived_statement)
        expect(result).not_to include(draft_statement)
      end
    end
  end

  describe '#statement?' do
    it 'returns true for statements' do
      measure = FactoryBot.build(:measure, measuretype: statement_measuretype)
      expect(measure.statement?).to eq(true)
    end

    it 'returns false for non-statements' do
      measure = FactoryBot.build(:measure, measuretype: not_statement_measuretype)
      expect(measure.statement?).to eq(false)
    end
  end

  describe '#publicly_accessible?' do
    it 'returns true when all conditions met' do
      measure = FactoryBot.build(:measure, public_api: true, measuretype: statement_measuretype,
                     is_archive: false, private: false, draft: false)
      expect(measure.publicly_accessible?).to eq(true)
    end

    it 'returns false when not a statement' do
      measure = FactoryBot.build(:measure, public_api: true, measuretype: not_statement_measuretype,
                     is_archive: false, private: false, draft: false)
      expect(measure.publicly_accessible?).to eq(false)
    end

    it 'returns false when not public_api' do
      measure = FactoryBot.build(:measure, public_api: false, measuretype: statement_measuretype,
                     is_archive: false, private: false, draft: false)
      expect(measure.publicly_accessible?).to eq(false)
    end

    it 'returns false when archived' do
      measure = FactoryBot.build(:measure, public_api: true, measuretype: statement_measuretype,
                     is_archive: true, private: false, draft: false)
      expect(measure.publicly_accessible?).to eq(false)
    end

    it 'returns false when confidential' do
      measure = FactoryBot.build(:measure, public_api: true, measuretype: statement_measuretype,
                     is_archive: false, private: true, draft: false)
      expect(measure.publicly_accessible?).to eq(false)
    end

    it 'returns false when draft' do
      measure = FactoryBot.build(:measure, public_api: true, measuretype: statement_measuretype,
                     is_archive: false, private: false, draft: true)
      expect(measure.publicly_accessible?).to eq(false)
    end
  end
end

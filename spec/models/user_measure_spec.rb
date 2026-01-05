require "rails_helper"

RSpec.describe UserMeasure, type: :model do
  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :measure }
  # handled by postgres
  # it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:measure_id) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:measure_id) }

  context "with a user and a measure" do
    let(:user) { FactoryBot.create(:user) }
    let(:measure) { FactoryBot.create(:measure) }

    let(:whodunnit) { FactoryBot.create(:user).id }
    before { allow(::PaperTrail.request).to receive(:whodunnit).and_return(whodunnit) }

    subject { described_class.create(user: user, measure: measure) }

    it "create sets the relationship_updated_at on the user" do
      expect { subject }.to change { user.reload.relationship_updated_at }
    end

    it "create sets the relationship_updated_at on the measure" do
      expect { subject }.to change { measure.reload.relationship_updated_at }
    end

    context "when the measure is a task" do
      let(:measure) { FactoryBot.create(:measure, :not_draft, measuretype: FactoryBot.create(:measuretype, notifications: true)) }

      it "create does not send a task updated email to the user it was just assigned to" do
        expect(TaskNotificationJob).not_to receive(:perform_in).with(anything, user.id, measure.id)
        expect(measure).not_to receive(:queue_task_updated_notifications!)

        subject
      end

      context "when there are other users assigned to the task" do
        let(:other_user) { FactoryBot.create(:user) }

        before do
          FactoryBot.create(:user_measure, user: other_user, measure: measure)
        end

        it "create sends a task updated email to the other users assigned to it" do
          expect(measure).not_to receive(:queue_task_updated_notifications!)
          expect(measure).to receive(:queue_task_updated_notification!)
            .with(user_id: other_user.id, measure_id: measure.id)
            .and_call_original
          expect(TaskNotificationJob).to receive(:perform_in)
            .with(anything, other_user.id, measure.id)
          expect(TaskNotificationJob).not_to receive(:perform_in)
            .with(anything, user.id, measure.id)

          subject
        end
      end
    end

    it "update sets the relationship_updated_at on the user" do
      subject
      expect { subject.touch }.to change { user.reload.relationship_updated_at }
    end

    it "update sets the relationship_updated_at on the measure" do
      subject
      expect { subject.touch }.to change { measure.reload.relationship_updated_at }
    end

    it "destroy sets the relationship_updated_at on the user" do
      expect { subject.destroy }.to change { user.reload.relationship_updated_at }
    end

    it "destroy sets the relationship_updated_at on the measure" do
      expect { subject.destroy }.to change { measure.reload.relationship_updated_at }
    end

    it "create sets the relationship_updated_by_id on the user" do
      expect { subject }.to change { user.reload.relationship_updated_by_id }.to(whodunnit)
    end

    it "create sets the relationship_updated_by_id on the measure" do
      expect { subject }.to change { measure.reload.relationship_updated_by_id }.to(whodunnit)
    end

    it "update sets the relationship_updated_by_id on the user" do
      subject
      user.update_column(:relationship_updated_by_id, nil)
      expect { subject.touch }.to change { user.reload.relationship_updated_by_id }.to(whodunnit)
    end

    it "update sets the relationship_updated_by_id on the measure" do
      subject
      measure.update_column(:relationship_updated_by_id, nil)
      expect { subject.touch }.to change { measure.reload.relationship_updated_by_id }.to(whodunnit)
    end

    it "destroy sets the relationship_updated_by_id on the user" do
      expect { subject.destroy }.to change { user.reload.relationship_updated_by_id }.to(whodunnit)
    end

    it "destroy sets the relationship_updated_by_id on the measure" do
      expect { subject.destroy }.to change { measure.reload.relationship_updated_by_id }.to(whodunnit)
    end
  end
end

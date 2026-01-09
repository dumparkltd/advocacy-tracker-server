# frozen_string_literal: true

require "rails_helper"
require "json"

RSpec.describe MeasuresController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:coordinator) { FactoryBot.create(:user, :coordinator) }
  let(:guest) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:user, :manager) }

  describe "GET index" do
    subject { get :index, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      it "guest will be forbidden" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      context "draft" do
        let!(:measure) { FactoryBot.create(:measure, draft: false) }
        let!(:draft_measure) { FactoryBot.create(:measure, draft: true) }

        it "admin will see draft measures" do
          sign_in admin
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "manager will see draft measures" do
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "coordinator will see draft measures" do
          sign_in coordinator
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "analyst will not see draft measures" do
          sign_in analyst

          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
        end
      end

      context "is_archive measures" do
        let!(:measure) { FactoryBot.create(:measure, :not_is_archive, :not_draft) }
        let!(:is_archive_measure) { FactoryBot.create(:measure, :is_archive, :not_draft) }

        it "admin will see" do
          sign_in admin
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "manager will not see" do
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
        end

        it "coordinator will not see" do
          sign_in coordinator
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
        end

        it "analyst will not see" do
          sign_in analyst

          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
        end
      end

      context "private" do
        let!(:measure) { FactoryBot.create(:measure, :not_private) }
        let!(:private_measure) { FactoryBot.create(:measure, :private) }
        let!(:private_measure_by_manager) { FactoryBot.create(:measure, :private, created_by_id: manager.id) }
        let!(:private_measure_by_coordinator) { FactoryBot.create(:measure, :private, created_by_id: coordinator.id) }

        it "admin will see" do
          sign_in admin
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(4)
        end

        it "manager who created will see" do
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "manager who didn't create will not see" do
          sign_in FactoryBot.create(:user, :manager)
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
        end

        it "coordinator who created will see" do
          sign_in coordinator
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(4)
        end

        it "coordinator who didn't create will see" do
          sign_in FactoryBot.create(:user, :coordinator)
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(4)
        end
      end
    end

    context "filters" do
      let(:category) { FactoryBot.create(:category) }
      let(:measure_different_category) { FactoryBot.create(:measure) }
      let(:indicator) { FactoryBot.create(:indicator) }
      let(:measure_different_indicator) { FactoryBot.create(:measure) }

      context "when signed in" do
        it "filters from category" do
          sign_in manager
          FactoryBot.create(:measuretype_taxonomy,
            measuretype: measure_different_category.measuretype,
            taxonomy: category.taxonomy)
          measure_different_category.categories << category
          subject = get :index, params: {category_id: category.id}, format: :json
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
          expect(json["data"][0]["id"]).to eq(measure_different_category.id.to_s)
        end

        it "filters from indicator" do
          sign_in manager
          measure_different_indicator.indicators << indicator
          subject = get :index, params: {indicator_id: indicator.id}, format: :json
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
          expect(json["data"][0]["id"]).to eq(measure_different_indicator.id.to_s)
        end
      end
    end
  end

  describe "GET show" do
    let(:measure) { FactoryBot.create(:measure) }
    let(:draft_measure) { FactoryBot.create(:measure, draft: true) }
    let(:private_measure) { FactoryBot.create(:measure, :private) }
    let(:private_measure_by_manager) { FactoryBot.create(:measure, :private, created_by_id: manager.id) }
    let(:requested_resource) { measure }

    subject { get :show, params: {id: requested_resource}, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      context "as admin" do
        before { sign_in admin }

        it { expect(subject).to be_ok }
      end

      context "as manager" do
        before { sign_in manager }

        it { expect(subject).to be_ok }

        context "who created will see" do
          let(:requested_resource) { private_measure_by_manager }

          it { expect(subject).to be_ok }
        end

        context "who didn't create won't see" do
          let(:requested_resource) { private_measure }

          it { expect(subject).to be_not_found }
        end
      end
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "not allow creating a measure" do
        post :create, format: :json, params: {measure: {title: "test", description: "test", target_date: "today"}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:category) { FactoryBot.create(:category) }
      let(:measuretype) { FactoryBot.create(:measuretype) }
      let(:params) do
        {
          measure: {
            title: "test",
            description: "test",
            measuretype_id: measuretype.id,
            target_date: "today"
          }
        }
      end

      subject { post :create, format: :json, params: params }

      it "will not allow a guest to create a measure" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will not allow an analyst to create a measure" do
        sign_in analyst
        expect(subject).to be_forbidden
      end

      it "will allow a manager to create a measure" do
        sign_in manager
        expect(subject).to be_created
      end

      it "will allow an admin to create a measure" do
        sign_in admin
        expect(subject).to be_created
      end

      context "is_archive" do
        let(:params) do
          {
            measure: {
              title: "test",
              description: "test",
              measuretype_id: measuretype.id,
              target_date: "today",
              is_archive: true
            }
          }
        end

        it "can't be set by manager" do
          sign_in manager
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "is_archive")).to eq false
        end

        it "can be set by admin" do
          sign_in admin
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "is_archive")).to eq true
        end
      end

      context "is_official" do
        let(:statement_measuretype) { FactoryBot.create(:measuretype, id: Measure::STATEMENT_TYPE_ID, title: "Statement") }

        let(:params) do
          {
            measure: {
              title: "test",
              description: "test",
              measuretype_id: statement_measuretype.id,
              target_date: "today",
              is_official: true
            }
          }
        end

        it "can't be set by manager" do
          sign_in manager
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "is_official")).to eq false
        end

        it "can be set by admin" do
          sign_in admin
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "is_official")).to eq true
        end
      end

      context "public_api" do
        let(:statement_measuretype) { FactoryBot.create(:measuretype, id: Measure::STATEMENT_TYPE_ID, title: "Statement") }
        let(:params) do
          {
            measure: {
              title: "test",
              description: "test",
              measuretype_id: statement_measuretype.id,
              target_date: "today",
              public_api: true,
              draft: false,
              is_archive: false,
              is_official: true,
              private: false
            }
          }
        end

        it "can't be set by manager" do
          sign_in manager
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq false
        end

        it "can be set by admin for statements" do
          sign_in admin
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq true
        end

        context "for non-statements" do
          let(:params) do
            {
              measure: {
                title: "test",
                description: "test",
                measuretype_id: measuretype.id,
                target_date: "today",
                public_api: true,
                draft: false,
                is_archive: false,
                private: false
              }
            }
          end

          it "will be filtered by policy" do
            sign_in admin
            expect(subject).to be_created
            expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq false
          end
        end
      end

      it "will record what manager created the measure", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq manager.id
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        post :create, format: :json, params: {measure: {description: "desc only"}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "PUT update" do
    let(:measure) { FactoryBot.create(:measure, :not_draft) }
    subject do
      put :update,
        format: :json,
        params: {id: measure,
                 measure: {title: "test update", description: "test update", target_date: "today update"}}
    end

    context "when not signed in" do
      it "not allow updating a measure" do
        expect(subject).to be_unauthorized
      end
    end

    context "when user signed in" do
      it "will not allow a guest to update a measure" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will not allow an analyst to update a measure" do
        sign_in analyst
        expect(subject).to be_forbidden
      end

      it "will allow a manager to update a measure" do
        sign_in manager
        expect(subject).to be_ok
      end

      it "will allow an admin to update a measure" do
        sign_in admin
        expect(subject).to be_ok
      end

      context "with a successful update to a task measure" do
        let(:measure) { FactoryBot.create(:measure, notifications: true) }
        let!(:user_measure) { FactoryBot.create(:user_measure, user: manager, measure: measure) }

        before do
          allow_any_instance_of(Measuretype).to receive(:notifications?).and_return(true)
          sign_in admin
        end

        context "when the task is not archived" do
          let(:measure) { FactoryBot.create(:measure, is_archive: false, notifications: true) }

          context "and is updated to archived" do
            it "will not create a notification for the user" do
              expect {
                put :update, format: :json, params: {id: measure, measure: {is_archive: true}}
              }.not_to change { ActionMailer::Base.deliveries.count }.from(0)
            end

            context "even if another field is set" do
              it "will not create a notification for the user" do
                expect {
                  put :update, format: :json, params: {id: measure, measure: {description: "updating", is_archive: true}}
                }.not_to change { ActionMailer::Base.deliveries.count }.from(0)
              end
            end
          end
        end

        %w[
          amount_comment
          amount
          code
          comment
          date_comment
          description
          outcome
          private
          status_comment
          target_comment
          target_date_comment
          target_date
          title
          url
        ].each do |attr|
          context "when the task is published" do
            let(:measure) { FactoryBot.create(:measure, :published, notifications: true) }

            it "notifies the user of an update to #{attr}" do
              expect(TaskNotificationJob).to receive(:perform_in).with(ENV.fetch("TASK_NOTIFICATION_DELAY", 20).to_i.seconds, user_measure.user_id, user_measure.measure_id)

              put :update, format: :json, params: {id: measure, measure: {attr => "test"}}
            end
          end

          context "when the task is draft" do
            let(:measure) { FactoryBot.create(:measure, :draft, notifications: true) }

            it "does not notify the user of an update to #{attr}" do
              expect(TaskNotificationJob).not_to receive(:perform_in)

              put :update, format: :json, params: {id: measure, measure: {attr => "test"}}
            end
          end

          context "when the task is archived" do
            let(:measure) { FactoryBot.create(:measure, :is_archive, :not_draft, notifications: true) }

            it "does not notify the user of an update to #{attr}" do
              expect(TaskNotificationJob).not_to receive(:perform_in)

              put :update, format: :json, params: {id: measure, measure: {attr => "test"}}
            end

            context "and is updated to not archived" do
              it "does notify the user of an update to #{attr}" do
                expect(TaskNotificationJob).to receive(:perform_in).with(ENV.fetch("TASK_NOTIFICATION_DELAY", 20).to_i.seconds, user_measure.user_id, user_measure.measure_id)

                put :update, format: :json, params: {id: measure, measure: {attr => "test", :is_archive => false}}
              end
            end
          end

          context "when the task is updated from draft" do
            let(:measure) { FactoryBot.create(:measure, :draft, notifications: true) }
            before { allow(UserMeasureMailer).to receive(:task_updated).and_return(double(deliver_now: true)) }

            it "does not notify the user of an update to #{attr}" do
              expect(TaskNotificationJob).not_to receive(:perform_in)

              put :update, format: :json, params: {id: measure, measure: {attr => "test", :draft => false}}
            end
          end
        end

        context "with a user measure assigned" do
          let(:user) { FactoryBot.create(:user) }
          let!(:user_measure) { FactoryBot.create(:user_measure, measure: measure, user: user) }
          before { sign_in user }

          it "will not send any notification emails" do
            expect(TaskNotificationJob).not_to receive(:perform_in)
          end

          context "when the measure changes from draft to published" do
            let(:measure) { FactoryBot.create(:measure, :draft, notifications: notifications) }

            subject do
              put :update,
                format: :json,
                params: {
                  id: measure,
                  measure: {description: "test update", draft: false, target_date: "today update", title: "test update"}
                }
            end

            before { sign_in manager }

            context "with measure notifications disabled" do
              let(:notifications) { false }

              it "will not queue a notification email" do
                expect(TaskNotificationJob).not_to receive(:perform_in)
              end
            end

            context "with measure notifications enabled" do
              before { allow(UserMeasureMailer).to receive(:task_updated).and_return(double(deliver_now: true)) }

              let(:notifications) { true }

              context "when the user is the updater" do
                let(:user) { manager }

                it "will not queue a notification email" do
                  expect(TaskNotificationJob).not_to receive(:perform_in)
                end
              end

              context "when the user is not the updater" do
                it "will not queue a notification email" do
                  expect(TaskNotificationJob).not_to receive(:perform_in)
                end
              end
            end
          end
        end

        context "is_archive" do
          subject do
            put :update, format: :json, params: {id: measure, measure: {is_archive: true}}
          end

          it "can't be set by manager" do
            sign_in manager
            expect(JSON.parse(subject.body).dig("data", "attributes", "is_archive")).to eq false
          end

          it "can be set by admin" do
            sign_in admin
            expect(JSON.parse(subject.body).dig("data", "attributes", "is_archive")).to eq true
          end
        end

        context "is_official" do
          let(:statement_measuretype) { FactoryBot.create(:measuretype, id: Measure::STATEMENT_TYPE_ID, title: "Statement") }
          let(:measure) { FactoryBot.create(:measure, measuretype: statement_measuretype, draft: false, is_archive: false, private: false, is_official: false) }

          subject do
            put :update, format: :json, params: {id: measure, measure: {is_official: true}}
          end

          it "can't be set by manager" do
            sign_in manager
            expect(JSON.parse(subject.body).dig("data", "attributes", "is_official")).to eq false
          end

          it "can be set by admin" do
            sign_in admin
            expect(JSON.parse(subject.body).dig("data", "attributes", "is_official")).to eq true
          end

          context "for non-statements" do
            let(:non_statement_measuretype) { FactoryBot.create(:measuretype, :not_a_statement) }
            let(:measure) { FactoryBot.create(:measure, measuretype: non_statement_measuretype, notifications: true) }

            it "can't be set even by admin" do
              sign_in admin
              expect(JSON.parse(subject.body).dig("data", "attributes", "is_official")).to eq false
            end
          end

        end

        context "public_api" do
          let(:statement_measuretype) { FactoryBot.create(:measuretype, id: Measure::STATEMENT_TYPE_ID, title: "Statement") }
          let(:measure) { FactoryBot.create(:measure, measuretype: statement_measuretype, draft: false, is_archive: false, private: false, is_official: true) }

          subject do
            put :update, format: :json, params: {
              id: measure,
              measure: {
                public_api: true,
                draft: false,
                is_archive: false,
                is_official: true,
                private: false
              }
            }
          end

          it "can't be set by manager" do
            sign_in manager
            expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq false
          end

          it "can be set by admin for statements" do
            sign_in admin
            expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq true
          end

          context "attempting to set for non-statement" do
            let(:non_statement_measuretype) { FactoryBot.create(:measuretype, :not_a_statement) }
            let(:measure) { FactoryBot.create(:measure, measuretype: non_statement_measuretype, draft: false, is_archive: false, private: false) }

            it "will be filtered by policy" do
              sign_in admin
              expect(subject).to be_ok
              expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq false
            end
          end
        end

        it "will reject an update where the last_updated_at is older than updated_at in the database" do
          sign_in manager
          measure_get = get :show, params: {id: measure}, format: :json
          json = JSON.parse(measure_get.body)
          current_update_at = json["data"]["attributes"]["updated_at"]

          Timecop.travel(Time.new + 15.days) do
            subject = put :update,
              format: :json,
              params: {id: measure,
                       measure: {title: "test update", description: "test updateeee", target_date: "today update", updated_at: current_update_at}}
            expect(subject).to be_ok
          end
          Timecop.travel(Time.new + 5.days) do
            subject = put :update,
              format: :json,
              params: {id: measure,
                       measure: {title: "test update", description: "test updatebbbb", target_date: "today update", updated_at: current_update_at}}
            expect(subject).to_not be_ok
          end
        end

        it "will record what manager updated the measure", versioning: true do
          expect(PaperTrail).to be_enabled
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq manager.id
        end

        it "will return the latest updated_by", versioning: true do
          expect(PaperTrail).to be_enabled
          measure.versions.first.update_column(:whodunnit, admin.id)
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq(manager.id)
        end

        it "will return an error if params are incorrect" do
          sign_in manager
          put :update, format: :json, params: {id: measure, measure: {title: ""}}
          expect(response).to have_http_status(422)
        end
      end
    end
  end

  describe "DELETE destroy" do
    let(:measure) { FactoryBot.create(:measure) }
    subject { delete :destroy, format: :json, params: {id: measure} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with a measure not belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure) }

          it "will not allow you to delete a measure" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure, created_by: user) }

          it "will not allow you to delete a measure" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with a measure not belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure) }

          it "will not allow you to delete a measure" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure, created_by: user) }

          it "will allow you to delete a measure" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with a measure not belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure) }

          it "will not allow you to delete a measure" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure, created_by: user) }

          it "will allow you to delete a measure" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with a measure not belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure) }

          it "will allow you to delete a measure" do
            expect(subject).to be_no_content
          end
        end

        context "with a measure belonging to the signed in user" do
          let(:measure) { FactoryBot.create(:measure, created_by: user) }

          it "will allow you to delete a measure" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

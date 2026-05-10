# frozen_string_literal: true

require "rails_helper"
require "json"

RSpec.describe UserMeasuresController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:coordinator) { FactoryBot.create(:user, :coordinator) }
  let(:manager) { FactoryBot.create(:user, :manager) }
  let(:guest) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }

  let(:statement_measuretype) { FactoryBot.create(:measuretype, id: Measure::STATEMENT_TYPE_ID, title: "Statement") }
  let(:regular_measuretype) { FactoryBot.create(:measuretype) }

  let(:published_statement) do
    FactoryBot.create(:measure,
      measuretype: statement_measuretype,
      public_api: true,
      is_official: true,
      is_archive: false,
      private: false,
      draft: false)
  end

  let(:unpublished_statement) do
    FactoryBot.create(:measure,
      measuretype: statement_measuretype,
      public_api: false,
      is_official: true,
      is_archive: false,
      private: false,
      draft: false)
  end

  let(:regular_measure) do
    FactoryBot.create(:measure,
      measuretype: regular_measuretype,
      draft: false)
  end

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

      it "analyst can view" do
        sign_in analyst
        expect(subject).to be_ok
      end

      it "manager can view" do
        sign_in manager
        expect(subject).to be_ok
      end

      it "coordinator can view" do
        sign_in coordinator
        expect(subject).to be_ok
      end

      it "admin can view" do
        sign_in admin
        expect(subject).to be_ok
      end
    end
  end

  describe "GET show" do
    let(:user_measure) do
      FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
    end

    subject { get :show, params: {id: user_measure}, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      it "guest will be forbidden" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "analyst can view" do
        sign_in analyst
        expect(subject).to be_ok
      end

      it "manager can view" do
        sign_in manager
        expect(subject).to be_ok
      end

      it "coordinator can view" do
        sign_in coordinator
        expect(subject).to be_ok
      end

      it "admin can view" do
        sign_in admin
        expect(subject).to be_ok
      end
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "not allow creating a user_measure" do
        post :create, format: :json, params: {user_measure: {user_id: 1, measure_id: 1}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      it "will not allow a guest to create a user_measure" do
        sign_in guest
        post :create, format: :json, params: {
          user_measure: {
            user_id: other_user.id,
            measure_id: regular_measure.id
          }
        }
        expect(response).to be_forbidden
      end

      it "will not allow an analyst to create a user_measure" do
        sign_in analyst
        post :create, format: :json, params: {
          user_measure: {
            user_id: other_user.id,
            measure_id: regular_measure.id
          }
        }
        expect(response).to be_forbidden
      end

      context "with regular measure" do
        subject do
          post :create,
            format: :json,
            params: {
              user_measure: {
                user_id: other_user.id,
                measure_id: regular_measure.id
              }
            }
        end

        it "will allow a manager to create a user_measure" do
          sign_in manager
          expect(subject).to be_created
        end

        it "will allow a coordinator to create a user_measure" do
          sign_in coordinator
          expect(subject).to be_created
        end

        it "will allow an admin to create a user_measure" do
          sign_in admin
          expect(subject).to be_created
        end
      end

      context "with measure notifications disabled" do
        let(:measure) { FactoryBot.create(:measure, notifications: false) }

        subject do
          post :create,
            format: :json,
            params: {
              user_measure: {
                user_id: other_user.id,
                measure_id: measure.id
              }
            }
        end

        it "will not send a notification email" do
          sign_in manager
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      context "with measure notifications enabled" do
        let(:measure) { FactoryBot.create(:measure, notifications: true) }

        subject do
          post :create,
            format: :json,
            params: {
              user_measure: {
                user_id: other_user.id,
                measure_id: measure.id
              }
            }
        end

        context "when the user is the creator" do
          subject do
            post :create,
              format: :json,
              params: {
                user_measure: {
                  user_id: manager.id,
                  measure_id: measure.id
                }
              }
          end

          it "will not send a notification email" do
            sign_in manager
            expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
          end
        end

        context "when the user is not the creator" do
          it "will send a notification email to the user" do
            sign_in manager
            expect { subject }.to change { ActionMailer::Base.deliveries.count }
            expect(ActionMailer::Base.deliveries.last.to).to eq [other_user.email]
            expect(ActionMailer::Base.deliveries.last.subject).to eq I18n.t(:subject, scope: [:user_measure_mailer, :created], measuretype: measure.measuretype.title.downcase)
          end
        end
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        # Create existing user_measure
        existing = FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)

        # Try to create duplicate (uniqueness validation should fail)
        post :create, format: :json, params: {
          user_measure: {
            user_id: other_user.id,
            measure_id: regular_measure.id
          }
        }
        expect(response).to have_http_status(422)
      end
    end

    context "with published statement" do
      let(:params) do
        {
          user_measure: {
            user_id: other_user.id,
            measure_id: published_statement.id
          }
        }
      end

      subject { post :create, format: :json, params: params }

      context "as manager" do
        it "will not allow creating relationship" do
          sign_in manager
          expect(subject).to be_forbidden
        end
      end

      context "as coordinator" do
        it "will allow creating relationship" do
          sign_in coordinator
          expect(subject).to be_created
        end
      end

      context "as admin" do
        it "will allow creating relationship" do
          sign_in admin
          expect(subject).to be_created
        end
      end
    end

    context "with unpublished statement" do
      let(:params) do
        {
          user_measure: {
            user_id: other_user.id,
            measure_id: unpublished_statement.id
          }
        }
      end

      subject { post :create, format: :json, params: params }

      it "will allow manager to create relationship" do
        sign_in manager
        expect(subject).to be_created
      end
    end
  end

  describe "DELETE destroy" do
    context "when not signed in" do
      let(:user_measure) do
        FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
      end

      it "not allow deleting a user_measure" do
        delete :destroy, format: :json, params: {id: user_measure.id}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:delete_request) { delete :destroy, format: :json, params: {id: user_measure} }

      context "as a guest" do
        context "with a user_measure not belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
          end

          it "will not allow you to delete a user_measure" do
            sign_in guest
            expect(delete_request).to be_forbidden
          end
        end

        context "with a user_measure belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure, created_by: guest)
          end

          it "will not allow you to delete a user_measure" do
            sign_in guest
            expect(delete_request).to be_forbidden
          end
        end
      end

      context "as an analyst" do
        context "with a user_measure not belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
          end

          it "will not allow you to delete a user_measure" do
            sign_in analyst
            expect(delete_request).to be_forbidden
          end
        end
      end

      context "as a manager" do
        context "with a user_measure not belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
          end

          it "will allow you to delete a user_measure" do
            sign_in manager
            expect(delete_request).to be_no_content
          end
        end

        context "with a user_measure belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure, created_by: manager)
          end

          it "will allow you to delete a user_measure" do
            sign_in manager
            expect(delete_request).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        context "with a user_measure not belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
          end

          it "will allow you to delete a user_measure" do
            sign_in coordinator
            expect(delete_request).to be_no_content
          end
        end

        context "with a user_measure belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure, created_by: coordinator)
          end

          it "will allow you to delete a user_measure" do
            sign_in coordinator
            expect(delete_request).to be_no_content
          end
        end
      end

      context "as an admin" do
        context "with a user_measure not belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure)
          end

          it "will allow you to delete a user_measure" do
            sign_in admin
            expect(delete_request).to be_no_content
          end
        end

        context "with a user_measure belonging to the signed in user" do
          let(:user_measure) do
            FactoryBot.create(:user_measure, user: other_user, measure: regular_measure, created_by: admin)
          end

          it "will allow you to delete a user_measure" do
            sign_in admin
            expect(delete_request).to be_no_content
          end
        end
      end

      context "with published statement" do
        let(:user_measure) do
          FactoryBot.create(:user_measure, user: other_user, measure: published_statement)
        end

        subject { delete :destroy, format: :json, params: {id: user_measure.id} }

        context "as manager" do
          it "will not allow deleting relationship" do
            sign_in manager
            expect(subject).to be_forbidden
          end
        end

        context "as coordinator" do
          it "will allow deleting relationship" do
            sign_in coordinator
            expect(subject).to be_no_content
          end
        end

        context "as admin" do
          it "will allow deleting relationship" do
            sign_in admin
            expect(subject).to be_no_content
          end
        end
      end

      context "with unpublished statement" do
        let(:user_measure) do
          FactoryBot.create(:user_measure, user: other_user, measure: unpublished_statement, created_by_id: manager.id)
        end

        subject { delete :destroy, format: :json, params: {id: user_measure.id} }

        it "will allow manager to delete relationship" do
          sign_in manager
          expect(subject).to be_no_content
        end
      end
    end
  end
end

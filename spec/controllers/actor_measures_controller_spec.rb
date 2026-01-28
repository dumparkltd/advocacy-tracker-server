require "rails_helper"
require "json"

RSpec.describe ActorMeasuresController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:coordinator) { FactoryBot.create(:user, :coordinator) }
  let(:manager) { FactoryBot.create(:user, :manager) }
  let(:guest) { FactoryBot.create(:user) }

  let(:actor) { FactoryBot.create(:actor) }
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
    let(:actor_measure) do
      FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
    end

    subject { get :show, params: {id: actor_measure}, format: :json }

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
      let(:params) do
        {
          actor_measure: {
            actor_id: actor.id,
            measure_id: regular_measure.id
          }
        }
      end

      it "not allow creating an actor_measure" do
        post :create, format: :json, params: params
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      it "will not allow a guest to create an actor_measure" do
        sign_in guest
        post :create, format: :json, params: {
          actor_measure: {
            actor_id: actor.id,
            measure_id: regular_measure.id
          }
        }
        expect(response).to be_forbidden
      end

      it "will not allow an analyst to create an actor_measure" do
        sign_in analyst
        post :create, format: :json, params: {
          actor_measure: {
            actor_id: actor.id,
            measure_id: regular_measure.id
          }
        }
        expect(response).to be_forbidden
      end

      context "with regular measure" do
        let(:params) do
          {
            actor_measure: {
              actor_id: actor.id,
              measure_id: regular_measure.id
            }
          }
        end

        subject { post :create, format: :json, params: params }

        it "will allow a manager to create an actor_measure" do
          sign_in manager
          expect(subject).to be_created
        end

        it "will allow a coordinator to create an actor_measure" do
          sign_in coordinator
          expect(subject).to be_created
        end

        it "will allow an admin to create an actor_measure" do
          sign_in admin
          expect(subject).to be_created
        end
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        # Create an actor with an inactive actortype
        inactive_actortype = FactoryBot.create(:actortype, is_active: false)
        inactive_actor = FactoryBot.create(:actor, actortype: inactive_actortype)

        post :create, format: :json, params: {
          actor_measure: {
            actor_id: inactive_actor.id,
            measure_id: regular_measure.id
          }
        }
        expect(response).to have_http_status(422)
      end
    end

    context "with published statement" do
      let(:params) do
        {
          actor_measure: {
            actor_id: actor.id,
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
          actor_measure: {
            actor_id: actor.id,
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

  describe "PUT update" do
    let(:actor_measure) do
      FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
    end

    subject do
      put :update,
        format: :json,
        params: {id: actor_measure.id, actor_measure: {value: 10}}
    end

    context "when not signed in" do
      it "not allow updating an actor_measure" do
        expect(subject).to be_unauthorized
      end
    end

    context "when signed in" do
      it "will not allow a guest to update an actor_measure" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will not allow an analyst to update an actor_measure" do
        sign_in analyst
        expect(subject).to be_forbidden
      end

      it "will allow a manager to update an actor_measure" do
        sign_in manager
        expect(subject).to be_ok
      end

      it "will allow a coordinator to update an actor_measure" do
        sign_in coordinator
        expect(subject).to be_ok
      end

      it "will allow an admin to update an actor_measure" do
        sign_in admin
        expect(subject).to be_ok
      end
    end

    context "with published statement" do
      let(:actor_measure) do
        FactoryBot.create(:actor_measure, actor: actor, measure: published_statement)
      end

      subject do
        put :update,
          format: :json,
          params: {id: actor_measure.id, actor_measure: {value: 10}}
      end

      context "as manager" do
        it "will not allow updating relationship" do
          sign_in manager
          expect(subject).to be_forbidden
        end
      end

      context "as coordinator" do
        it "will allow updating relationship" do
          sign_in coordinator
          expect(subject).to be_ok
        end
      end

      context "as admin" do
        it "will allow updating relationship" do
          sign_in admin
          expect(subject).to be_ok
        end
      end
    end
  end

  describe "DELETE destroy" do
    context "when not signed in" do
      let(:actor_measure) do
        FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
      end

      it "not allow deleting an actor_measure" do
        delete :destroy, format: :json, params: {id: actor_measure.id}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:delete_request) { delete :destroy, format: :json, params: {id: actor_measure} }

      context "as a guest" do
        context "with an actor_measure not belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
          end

          it "will not allow you to delete an actor_measure" do
            sign_in guest
            expect(delete_request).to be_forbidden
          end
        end

        context "with an actor_measure belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure, created_by: guest)
          end

          it "will not allow you to delete an actor_measure" do
            sign_in guest
            expect(delete_request).to be_forbidden
          end
        end
      end

      context "as an analyst" do
        context "with an actor_measure not belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
          end

          it "will not allow you to delete an actor_measure" do
            sign_in analyst
            expect(delete_request).to be_forbidden
          end
        end
      end

      context "as a manager" do
        context "with an actor_measure not belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
          end

          it "will allow you to delete an actor_measure" do
            sign_in manager
            expect(delete_request).to be_no_content
          end
        end

        context "with an actor_measure belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure, created_by: manager)
          end

          it "will allow you to delete an actor_measure" do
            sign_in manager
            expect(delete_request).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        context "with an actor_measure not belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
          end

          it "will allow you to delete an actor_measure" do
            sign_in coordinator
            expect(delete_request).to be_no_content
          end
        end

        context "with an actor_measure belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure, created_by: coordinator)
          end

          it "will allow you to delete an actor_measure" do
            sign_in coordinator
            expect(delete_request).to be_no_content
          end
        end
      end

      context "as an admin" do
        context "with an actor_measure not belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure)
          end

          it "will allow you to delete an actor_measure" do
            sign_in admin
            expect(delete_request).to be_no_content
          end
        end

        context "with an actor_measure belonging to the signed in user" do
          let(:actor_measure) do
            FactoryBot.create(:actor_measure, actor: actor, measure: regular_measure, created_by: admin)
          end

          it "will allow you to delete an actor_measure" do
            sign_in admin
            expect(delete_request).to be_no_content
          end
        end
      end

      context "with published statement" do
        let(:actor_measure) do
          FactoryBot.create(:actor_measure, actor: actor, measure: published_statement)
        end

        subject { delete :destroy, format: :json, params: {id: actor_measure.id} }

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
        let(:actor_measure) do
          FactoryBot.create(:actor_measure, actor: actor, measure: unpublished_statement, created_by_id: manager.id)
        end

        subject { delete :destroy, format: :json, params: {id: actor_measure.id} }

        it "will allow manager to delete relationship" do
          sign_in manager
          expect(subject).to be_no_content
        end
      end
    end
  end
end

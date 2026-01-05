# frozen_string_literal: true

require "rails_helper"
require "json"

RSpec.describe ActorsController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:coordinator) { FactoryBot.create(:user, :coordinator) }
  let(:guest) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:user, :manager) }

  describe "Get index" do
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
        let!(:actor) { FactoryBot.create(:actor, :not_draft) }
        let!(:draft_actor) { FactoryBot.create(:actor) }

        it "admin will see draft actors" do
          sign_in admin
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "manager will see draft actors" do
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "coordinator will see draft actors" do
          sign_in coordinator
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "analyst will not see draft actors" do
          sign_in analyst

          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
        end
      end

      context "is_archive actors" do
        let!(:actor) { FactoryBot.create(:actor, :not_is_archive) }
        let!(:is_archive_actor) { FactoryBot.create(:actor, :is_archive) }

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

        it "analyst will not see" do
          sign_in analyst

          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(0)
        end
      end

      context "private" do
        let!(:actor) { FactoryBot.create(:actor, :not_private) }
        let!(:private_actor) { FactoryBot.create(:actor, :private) }
        let!(:private_actor_by_manager) { FactoryBot.create(:actor, :private, created_by_id: manager.id) }

        it "admin will see" do
          sign_in admin
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(3)
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
      end
    end
  end

  describe "Get show" do
    let(:actor) { FactoryBot.create(:actor) }
    let(:draft_actor) { FactoryBot.create(:actor, draft: true) }
    let(:private_actor) { FactoryBot.create(:actor, :private) }
    let(:private_actor_by_manager) { FactoryBot.create(:actor, :private, created_by_id: manager.id) }
    let(:requested_resource) { actor }

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
          let(:requested_resource) { private_actor_by_manager }

          it { expect(subject).to be_ok }
        end

        context "who didn't create won't see" do
          let(:requested_resource) { private_actor }

          it { expect(subject).to be_not_found }
        end
      end
    end
  end

  describe "Post create" do
    context "when not signed in" do
      it "not allow creating an actor" do
        post :create, format: :json, params: {actor: {title: "test", description: "test", target_date: "today"}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:category) { FactoryBot.create(:category) }
      let(:actortype) { FactoryBot.create(:actortype) }
      let(:params) do
        {
          actor: {
            code: "test",
            title: "test",
            description: "test",
            actortype_id: actortype.id,
            target_date: "today"
          }
        }
      end
      subject { post :create, format: :json, params: params }

      it "will not allow a guest to create an actor" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will not allow an analyst to create an actor" do
        sign_in analyst
        expect(subject).to be_forbidden
      end

      it "will allow a manager to create an actor" do
        sign_in manager
        expect(subject).to be_created
      end

      it "will allow an admin to create an actor" do
        sign_in admin
        expect(subject).to be_created
      end

      context "is_archive" do
        let(:params) do
          {
            actor: {
              code: "test",
              title: "test",
              description: "test",
              actortype_id: actortype.id,
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

      it "will record what manager created the actor", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq manager.id
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        post :create, format: :json, params: {actor: {description: "desc only"}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "PUT update" do
    let(:actor) { FactoryBot.create(:actor, :not_draft) }
    subject do
      put :update,
        format: :json,
        params: {id: actor,
                 actor: {title: "test update", description: "test update", target_date: "today update"}}
    end

    context "when not signed in" do
      it "not allow updating an actor" do
        expect(subject).to be_unauthorized
      end
    end

    context "when user signed in" do
      it "will not allow a guest to update an actor" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will not allow an analyst to update an actor" do
        sign_in analyst
        expect(subject).to be_forbidden
      end

      it "will allow a manager to update an actor" do
        sign_in manager
        expect(subject).to be_ok
      end

      it "will allow an admin to update an actor" do
        sign_in admin
        expect(subject).to be_ok
      end

      context "is_archive" do
        subject do
          put :update, format: :json, params: {id: actor, actor: {is_archive: true}}
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

      it "will reject an update where the last_updated_at is older than updated_at in the database" do
        sign_in manager
        actor_get = get :show, params: {id: actor}, format: :json
        json = JSON.parse(actor_get.body)
        current_update_at = json["data"]["attributes"]["updated_at"]

        Timecop.travel(Time.new + 15.days) do
          subject = put :update,
            format: :json,
            params: {id: actor,
                     actor: {title: "test update", description: "test updateeee", target_date: "today update", updated_at: current_update_at}}
          expect(subject).to be_ok
        end
        Timecop.travel(Time.new + 5.days) do
          subject = put :update,
            format: :json,
            params: {id: actor,
                     actor: {title: "test update", description: "test updatebbbb", target_date: "today update", updated_at: current_update_at}}
          expect(subject).to_not be_ok
        end
      end

      it "will record what manager updated the actor", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq manager.id
      end

      it "will return the latest updated_by", versioning: true do
        expect(PaperTrail).to be_enabled
        actor.versions.first.update_column(:whodunnit, admin.id)
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq(manager.id)
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        put :update, format: :json, params: {id: actor, actor: {title: ""}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "DELETE destroy" do
    let(:actor) { FactoryBot.create(:actor) }
    subject { delete :destroy, format: :json, params: {id: actor} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with an actor not belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor) }

          it "will not allow you to delete an actor" do
            expect(subject).to be_forbidden
          end
        end

        context "with an actor belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor, created_by: user) }

          it "will not allow you to delete an actor" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with an actor not belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor) }

          it "will not allow you to delete an actor" do
            expect(subject).to be_forbidden
          end
        end

        context "with an actor belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor, created_by: user) }

          it "will allow you to delete an actor" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with an actor not belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor) }

          it "will not allow you to delete an actor" do
            expect(subject).to be_forbidden
          end
        end

        context "with an actor belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor, created_by: user) }

          it "will allow you to delete an actor" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with an actor not belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor) }

          it "will allow you to delete an actor" do
            expect(subject).to be_no_content
          end
        end

        context "with an actor belonging to the signed in user" do
          let(:actor) { FactoryBot.create(:actor, created_by: user) }

          it "will allow you to delete an actor" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

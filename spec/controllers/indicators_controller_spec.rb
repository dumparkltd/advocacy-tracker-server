# frozen_string_literal: true

require "rails_helper"
require "json"

RSpec.describe IndicatorsController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:coordinator) { FactoryBot.create(:user, :coordinator) }
  let(:guest) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:user, :manager) }

  describe "Get index" do
    subject { get :index, format: :json }
    let!(:indicator) { FactoryBot.create(:indicator) }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      it "guest will be forbidden" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      context "draft" do
        let!(:draft_indicator) { FactoryBot.create(:indicator, draft: true) }

        it "admin will see draft indicators" do
          sign_in admin
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "manager will see draft indicators" do
          sign_in manager
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end

        it "coordinator will see draft indicators" do
          sign_in coordinator
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(2)
        end
      end

      context "is_archive indicators" do
        let!(:indicator) { FactoryBot.create(:indicator, :not_is_archive, :not_draft) }
        let!(:is_archive_indicator) { FactoryBot.create(:indicator, :is_archive, :not_draft) }

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
    end

    context "filters" do
      let(:measure) { FactoryBot.create(:measure) }
      let(:indicator_different_measure) { FactoryBot.create(:indicator) }

      context "when signed in" do
        it "filters from measures" do
          sign_in manager
          indicator_different_measure.measures << measure
          subject = get :index, params: {measure_id: measure.id}, format: :json
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
          expect(json["data"][0]["id"]).to eq(indicator_different_measure.id.to_s)
        end
      end
    end
  end

  describe "Get show" do
    let(:indicator) { FactoryBot.create(:indicator) }
    let(:draft_indicator) { FactoryBot.create(:indicator, draft: true) }
    let(:private_indicator) { FactoryBot.create(:indicator, :private) }
    let(:private_indicator_by_coordinator) { FactoryBot.create(:indicator, :private, created_by_id: coordinator.id) }
    let(:private_indicator_by_manager) { FactoryBot.create(:indicator, :private, created_by_id: manager.id) }
    let(:requested_resource) { indicator }

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
          let(:requested_resource) { private_indicator_by_manager }

          it { expect(subject).to be_ok }
        end

        context "who didn't create won't see" do
          let(:requested_resource) { private_indicator }

          it { expect(subject).to be_not_found }
        end
      end

      context "as coordinator" do
        before { sign_in coordinator }

        it { expect(subject).to be_ok }

        context "who created will see" do
          let(:requested_resource) { private_indicator_by_coordinator }

          it { expect(subject).to be_ok }
        end

        context "who didn't create will see" do
          let(:requested_resource) { private_indicator }

          it { expect(subject).to be_ok }
        end
      end
    end
  end

  describe "Post create" do
    context "when not signed in" do
      it "not allow creating an indicator" do
        post :create, format: :json, params: {indicator: {title: "test", description: "test", target_date: "today"}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:measure) { FactoryBot.create(:measure) }
      let(:params) do
        {
          indicator: {
            title: "test",
            description: "test",
            target_date: "today"
          }
        }
      end

      subject { post :create, format: :json, params: params }

      it "will not allow a guest to create an indicator" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will allow a manager to create an indicator" do
        sign_in manager
        expect(subject).to be_created
      end

      context "is_archive" do
        let(:params) do
          {
            indicator: {
              title: "test",
              description: "test",
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

      context "public_api" do
        let(:params) do
          {
            indicator: {
              title: "test",
              description: "test",
              target_date: "today",
              public_api: true,
              draft: false,
              is_archive: false,
              private: false
            }
          }
        end

        it "can't be set by manager" do
          sign_in manager
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq false
        end

        it "can be set by coordinator" do
          sign_in coordinator
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq true
        end
        it "can be set by admin" do
          sign_in admin
          expect(subject).to be_created
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq true
        end
      end

      it "will record what manager created the indicator", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json["data"]["attributes"]["updated_by_id"].to_i).to eq manager.id
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        post :create, format: :json, params: {indicator: {description: "desc only"}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "PUT update" do
    let!(:indicator) { FactoryBot.create(:indicator) }
    subject do
      put :update,
        format: :json,
        params: {id: indicator,
                 indicator: {title: "test update", description: "test update", target_date: "today update"}}
    end

    context "when not signed in" do
      it "not allow updating an indicator" do
        expect(subject).to be_unauthorized
      end
    end

    context "when user signed in" do
      it "will not allow a guest to update an indicator" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will allow a manager to update an indicator" do
        sign_in manager
        expect(subject).to be_ok
      end

      context "is_archive" do
        subject do
          put :update, format: :json, params: {id: indicator, indicator: {is_archive: true}}
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

      context "public_api" do
        subject do
          put :update, format: :json, params: {
            id: indicator,
            indicator: {
              public_api: true,
              draft: false,
              is_archive: false,
              private: false
            }
          }
        end

        it "can't be set by manager" do
          sign_in manager
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq false
        end

        it "can be set by coordinator" do
          sign_in coordinator
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq true
        end

        it "can be set by admin" do
          sign_in admin
          expect(JSON.parse(subject.body).dig("data", "attributes", "public_api")).to eq true
        end
      end

      it "will reject an update where the last_updated_at is older than updated_at in the database" do
        sign_in manager
        indicator_get = get :show, params: {id: indicator}, format: :json
        json = JSON.parse(indicator_get.body)
        current_update_at = json["data"]["attributes"]["updated_at"]

        Timecop.travel(Time.new + 15.days) do
          subject = put :update,
            format: :json,
            params: {id: indicator,
                     indicator: {title: "test update", description: "test updateeee", target_date: "today update", updated_at: current_update_at}}
          expect(subject).to be_ok
        end
        Timecop.travel(Time.new + 5.days) do
          subject = put :update,
            format: :json,
            params: {id: indicator,
                     indicator: {title: "test update", description: "test updatebbbb", target_date: "today update", updated_at: current_update_at}}
          expect(subject).to_not be_ok
        end
      end

      it "will record what manager updated the indicator", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json["data"]["attributes"]["updated_by_id"].to_i).to eq manager.id
      end

      it "will return the latest updated_by", versioning: true do
        expect(PaperTrail).to be_enabled
        indicator.versions.first.update_column(:whodunnit, admin.id)
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json["data"]["attributes"]["updated_by_id"].to_i).to eq(manager.id)
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        put :update, format: :json, params: {id: indicator, indicator: {title: ""}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "Delete destroy" do
    let(:subject) { delete :destroy, format: :json, params: {id: indicator} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with an indicator not belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator) }

          it "will not allow you to delete an indicator" do
            expect(subject).to be_forbidden
          end
        end

        context "with an indicator belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator, created_by: user) }

          it "will not allow you to delete an indicator" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with an indicator not belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator) }

          it "will not allow you to delete an indicator" do
            expect(subject).to be_forbidden
          end
        end

        context "with an indicator belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator, created_by: user) }

          it "will allow you to delete an indicator" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with an indicator not belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator) }

          it "will not allow you to delete an indicator" do
            expect(subject).to be_forbidden
          end
        end

        context "with an indicator belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator, created_by: user) }

          it "will allow you to delete an indicator" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with an indicator not belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator) }

          it "will allow you to delete an indicator" do
            expect(subject).to be_no_content
          end
        end

        context "with an indicator belonging to the signed in user" do
          let(:indicator) { FactoryBot.create(:indicator, created_by: user) }

          it "will allow you to delete an indicator" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

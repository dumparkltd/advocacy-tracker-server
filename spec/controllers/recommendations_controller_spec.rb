# frozen_string_literal: true

require "rails_helper"
require "json"

RSpec.describe RecommendationsController, type: :controller do
  describe "Get index" do
    subject { get :index, format: :json }
    let!(:recommendation) { FactoryBot.create(:recommendation) }
    let!(:draft_recommendation) { FactoryBot.create(:recommendation, draft: true) }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      let(:guest) { FactoryBot.create(:user) }
      let(:user) { FactoryBot.create(:user, :manager) }

      it "guest will be forbidden" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "manager will see draft recommendations" do
        sign_in user
        json = JSON.parse(subject.body)
        expect(json["data"].length).to eq(2)
      end
    end

    context "filters" do
      let(:category) { FactoryBot.create(:category) }
      let(:recommendation_different_category) { FactoryBot.create(:recommendation) }
      let(:measure) { FactoryBot.create(:measure) }
      let(:recommendation_different_measure) { FactoryBot.create(:recommendation) }

      context "when signed in" do
        let(:user) { FactoryBot.create(:user, :manager) }

        it "filters from category" do
          sign_in user
          recommendation_different_category.categories << category
          subject = get :index, params: {category_id: category.id}, format: :json
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
          expect(json["data"][0]["id"]).to eq(recommendation_different_category.id.to_s)
        end

        it "filters from measure" do
          sign_in user
          recommendation_different_measure.measures << measure
          subject = get :index, params: {measure_id: measure.id}, format: :json
          json = JSON.parse(subject.body)
          expect(json["data"].length).to eq(1)
          expect(json["data"][0]["id"]).to eq(recommendation_different_measure.id.to_s)
        end
      end
    end
  end

  describe "Get show" do
    let(:recommendation) { FactoryBot.create(:recommendation) }
    let(:draft_recommendation) { FactoryBot.create(:recommendation, draft: true) }
    subject { get :show, params: {id: recommendation}, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end
  end

  describe "Post create" do
    context "when not signed in" do
      it "not allow creating a recommendation" do
        post :create, format: :json, params: {recommendation: {title: "test", reference: "1"}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:guest) { FactoryBot.create(:user) }
      let(:user) { FactoryBot.create(:user, :manager) }
      let(:category) { FactoryBot.create(:category) }
      subject do
        post :create,
          format: :json,
          params: {
            recommendation: {
              title: "test",
              reference: "1"
            }
          }
      end

      it "will not allow a guest to create a recommendation" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will allow a manager to create a recommendation" do
        sign_in user
        expect(subject).to be_created
      end

      it "will record what manager created the recommendation", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in user
        json = JSON.parse(subject.body)
        expect(json["data"]["attributes"]["updated_by_id"].to_i).to eq user.id
      end

      it "will return an error if params are incorrect" do
        sign_in user
        post :create, format: :json, params: {recommendation: {description: "desc only"}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "PUT update" do
    let(:recommendation) { FactoryBot.create(:recommendation) }
    subject do
      put :update,
        format: :json,
        params: {id: recommendation,
                 recommendation: {title: "test update", description: "test update", target_date: "today update"}}
    end

    context "when not signed in" do
      it "not allow updating a recommendation" do
        expect(subject).to be_unauthorized
      end
    end

    context "when user signed in" do
      let(:admin) { FactoryBot.create(:user, :admin) }
      let(:guest) { FactoryBot.create(:user) }
      let(:user) { FactoryBot.create(:user, :manager) }

      it "will not allow a guest to update a recommendation" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will allow a manager to update a recommendation" do
        sign_in user
        expect(subject).to be_ok
      end

      it "will reject an update where the last_updated_at is older than updated_at in the database" do
        sign_in user
        recommendation_get = get :show, params: {id: recommendation}, format: :json
        json = JSON.parse(recommendation_get.body)
        current_update_at = json["data"]["attributes"]["updated_at"]

        Timecop.travel(Time.new + 15.days) do
          subject = put :update,
            format: :json,
            params: {id: recommendation,
                     recommendation: {title: "test update", description: "test updateeee", target_date: "today update", updated_at: current_update_at}}
          expect(subject).to be_ok
        end
        Timecop.travel(Time.new + 5.days) do
          subject = put :update,
            format: :json,
            params: {id: recommendation,
                     recommendation: {title: "test update", description: "test updatebbbb", target_date: "today update", updated_at: current_update_at}}
          expect(subject).to_not be_ok
        end
      end

      it "will record what manager updated the recommendation", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in user
        json = JSON.parse(subject.body)
        expect(json["data"]["attributes"]["updated_by_id"].to_i).to eq user.id
      end

      it "will return the latest updated_by", versioning: true do
        expect(PaperTrail).to be_enabled
        recommendation.versions.first.update_column(:whodunnit, admin.id)
        sign_in user
        json = JSON.parse(subject.body)
        expect(json["data"]["attributes"]["updated_by_id"].to_i).to eq(user.id)
      end

      it "will return an error if params are incorrect" do
        sign_in user
        put :update, format: :json, params: {id: recommendation, recommendation: {title: ""}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "Delete destroy" do
    let(:subject) { delete :destroy, format: :json, params: {id: recommendation} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with a recommendation not belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation) }

          it "will not allow you to delete a recommendation" do
            expect(subject).to be_forbidden
          end
        end

        context "with a recommendation belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation, created_by: user) }

          it "will not allow you to delete a recommendation" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with a recommendation not belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation) }

          it "will not allow you to delete a recommendation" do
            expect(subject).to be_forbidden
          end
        end

        context "with a recommendation belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation, created_by: user) }

          it "will allow you to delete a recommendation" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with a recommendation not belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation) }

          it "will not allow you to delete a recommendation" do
            expect(subject).to be_forbidden
          end
        end

        context "with a recommendation belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation, created_by: user) }

          it "will allow you to delete a recommendation" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with a recommendation not belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation) }

          it "will allow you to delete a recommendation" do
            expect(subject).to be_no_content
          end
        end

        context "with a recommendation belonging to the signed in user" do
          let(:recommendation) { FactoryBot.create(:recommendation, created_by: user) }

          it "will allow you to delete a recommendation" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

require "rails_helper"
require "json"

RSpec.describe MeasureActorsController, type: :controller do
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:guest) { FactoryBot.create(:user) }
  let(:user) { FactoryBot.create(:user, :manager) }

  describe "Get index" do
    subject { get :index, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      context "as analyst" do
        before { sign_in FactoryBot.create(:user, :analyst) }

        it { expect(subject).to be_ok }
      end

      context "as manager" do
        before { sign_in FactoryBot.create(:user, :manager) }

        it { expect(subject).to be_ok }
      end

      context "as coordinator" do
        before { sign_in FactoryBot.create(:user, :coordinator) }

        it { expect(subject).to be_ok }
      end

      context "as admin" do
        before { sign_in FactoryBot.create(:user, :admin) }

        it { expect(subject).to be_ok }
      end
    end
  end

  describe "Get show" do
    let(:measure_actor) { FactoryBot.create(:measure_actor) }
    subject { get :show, params: {id: measure_actor}, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end

    context "when signed in" do
      context "as analyst" do
        before { sign_in FactoryBot.create(:user, :analyst) }

        it { expect(subject).to be_ok }
      end

      context "as coordinator" do
        before { sign_in FactoryBot.create(:user, :coordinator) }

        it { expect(subject).to be_ok }
      end

      context "as manager" do
        before { sign_in FactoryBot.create(:user, :manager) }

        it { expect(subject).to be_ok }
      end

      context "as admin" do
        before { sign_in FactoryBot.create(:user, :admin) }

        it { expect(subject).to be_ok }
      end
    end
  end

  describe "PUT update" do
    let(:measure_actor) { FactoryBot.create(:measure_actor) }
    subject do
      put :update,
        format: :json,
        params: {id: measure_actor,
                 measure_actor: {value: "4.2"}}
    end

    context "when not signed in" do
      it "not allow updating a measure_actor" do
        expect(subject).to be_unauthorized
      end
    end

    context "when user signed in" do
      it "will not allow a guest to update a measure_actor" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will not allow an analyst to update an measure_actor" do
        sign_in analyst
        expect(subject).to be_forbidden
      end

      it "will allow a manager to update a measure_actor" do
        sign_in user
        expect(subject).to be_ok
        json = JSON.parse(subject.body)
        expect(json.dig("data", "attributes", "value")).to eq("4.2")
      end

      it "will return an error if params are incorrect" do
        sign_in user
        put :update, format: :json, params: {id: measure_actor,
                                             measure_actor: {actor_id: 999}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "Delete destroy" do
    let(:subject) { delete :destroy, format: :json, params: {id: measure_actor} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with a measure_actor not belonging to the signed in user" do
          let(:measure_actor) { FactoryBot.create(:measure_actor) }

          it "will not allow you to delete a measure_actor" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure_actor belonging to the signed in user" do
          let(:measure_actor) { FactoryBot.create(:measure_actor, created_by: user) }

          it "will not allow you to delete a measure_actor" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with a measure_actor not belonging to the signed in user" do
          let(:measure_actor) { FactoryBot.create(:measure_actor) }

          it "will allow you to delete a measure_actor" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with a measure_actor not belonging to the signed in user" do
          let(:measure_actor) { FactoryBot.create(:measure_actor) }

          it "will allow you to delete a measure_actor" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with a measure_actor not belonging to the signed in user" do
          let(:measure_actor) { FactoryBot.create(:measure_actor) }

          it "will allow you to delete a measure_actor" do
            expect(subject).to be_no_content
          end
        end

        context "with a measure_actor belonging to the signed in user" do
          let(:measure_actor) { FactoryBot.create(:measure_actor, created_by: user) }

          it "will allow you to delete a measure_actor" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

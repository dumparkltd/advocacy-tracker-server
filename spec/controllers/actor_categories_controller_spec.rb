require "rails_helper"
require "json"

RSpec.describe ActorCategoriesController, type: :controller do
  let(:category) { FactoryBot.create(:category) }
  let(:actor) { FactoryBot.create(:actor) }
  let!(:actortype_taxonomy) do
    FactoryBot.create(:actortype_taxonomy, actortype: actor.actortype, taxonomy: category.taxonomy)
  end

  describe "Get index" do
    subject { get :index, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end
  end

  describe "Get show" do
    let(:actor_category) { FactoryBot.create(:actor_category, category: category, actor: actor) }
    subject { get :show, params: {id: actor_category}, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end
  end

  describe "Post create" do
    context "when not signed in" do
      it "not allow creating an actor_category" do
        post :create, format: :json, params: {actor_category: {actor_id: 1, category_id: 1}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let(:guest) { FactoryBot.create(:user) }
      let(:user) { FactoryBot.create(:user, :manager) }
      let(:coordinator) { FactoryBot.create(:user, :coordinator) }

      subject do
        post :create,
          format: :json,
          params: {
            actor_category: {
              actor_id: actor.id,
              category_id: category.id
            }
          }
      end

      it "will not allow a guest to create an actor_category" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will allow a manager to create an actor_category" do
        sign_in user
        expect(subject).to be_created
      end

      it "will allow a coordinator to create an actor_category" do
        sign_in coordinator
        expect(subject).to be_created
      end

      it "will return an error if params are incorrect" do
        sign_in user
        post :create, format: :json, params: {actor_category: {description: "desc only", taxonomy_id: 999}}
        expect(response).to have_http_status(422)
      end

      it "will record what manager created the actor category", versioning: true do
        expect(PaperTrail).to be_enabled
        sign_in user
        json = JSON.parse(subject.body)
        expect(json.dig("data", "attributes", "updated_by_id").to_i).to eq user.id
      end
    end
  end

  describe "Delete destroy" do
    let(:subject) { delete :destroy, format: :json, params: {id: actor_category} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with an actor_category not belonging to the signed in user" do
          let(:actor_category) { FactoryBot.create(:actor_category, category:, actor:) }

          it "will not allow you to delete the actor_category" do
            expect(subject).to be_forbidden
          end
        end

        context "with an actor_category belonging to the signed in user" do
          let(:actor_category) { FactoryBot.create(:actor_category, category:, actor:, created_by: user) }

          it "will not allow you to delete the actor_category" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with an actor_category not belonging to the signed in user" do
          let(:actor_category) { FactoryBot.create(:actor_category, category:, actor:) }

          it "will allow you to delete the actor_category" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with an actor_category not belonging to the signed in user" do
          let(:actor_category) { FactoryBot.create(:actor_category, category:, actor:) }

          it "will allow you to delete the actor_category" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with an actor_category not belonging to the signed in user" do
          let(:actor_category) { FactoryBot.create(:actor_category, category:, actor:) }

          it "will allow you to delete the actor_category" do
            expect(subject).to be_no_content
          end
        end

        context "with an actor_category belonging to the signed in user" do
          let(:actor_category) { FactoryBot.create(:actor_category, category:, actor:, created_by: user) }

          it "will allow you to delete the actor_category" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

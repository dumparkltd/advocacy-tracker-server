require "rails_helper"
require "json"

RSpec.describe MeasureMeasuresController, type: :controller do
  let!(:statement_measuretype) { FactoryBot.create(:measuretype, :statement) }
  describe "Get index" do
    subject { get :index, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end
  end

  describe "Get show" do
    let(:measure_measure) do
      main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
      other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
      FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
    end
    subject { get :show, params: {id: measure_measure}, format: :json }

    context "when not signed in" do
      it { expect(subject).to be_forbidden }
    end
  end

  describe "Post create" do
    context "when not signed in" do
      it "not allow creating a measure_measure" do
        post :create, format: :json, params: {measure_measure: {measure_id: 1, other_measure_id: 1}}
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      let!(:statement_measuretype) { FactoryBot.create(:measuretype, :statement) }

      let(:coordinator) { FactoryBot.create(:user, :coordinator) }
      let(:guest) { FactoryBot.create(:user) }
      let(:manager) { FactoryBot.create(:user, :manager) }

      # Create the main measure
      let(:measure) do
        FactoryBot.create(:measure, measuretype: statement_measuretype)
      end

      # Create the other_measure, explicitly reusing the same measuretype
      let(:other_measure) do
        FactoryBot.create(:measure, measuretype: measure.measuretype)
      end

      subject do
        post :create,
          format: :json,
          params: {
            measure_measure: {
              measure_id: measure.id,
              other_measure_id: other_measure.id
            }
          }
      end

      it "will not allow a guest to create a measure_measure" do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it "will allow a manager to create a measure_measure" do
        sign_in manager
        expect(subject).to be_created
      end

      it "will allow a coordinator to create a measure_measure" do
        sign_in coordinator
        expect(subject).to be_created
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        post :create, format: :json, params: {measure_measure: {description: "desc only", taxonomy_id: 999}}
        expect(response).to have_http_status(422)
      end
    end
  end

  describe "Delete destroy" do
    let(:subject) { delete :destroy, format: :json, params: {id: measure_measure} }

    context "when signed in" do
      before { sign_in user }

      context "as a guest" do
        let(:user) { FactoryBot.create(:user) }

        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will not allow you to delete a measure_measure" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure_measure belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure, created_by: user)
          end

          it "will not allow you to delete a measure_measure" do
            expect(subject).to be_forbidden
          end
        end
      end

      context "as a manager" do
        let(:user) { FactoryBot.create(:user, :manager) }

        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will not allow you to delete a measure_measure" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure_measure belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure, created_by: user)
          end

          it "will allow you to delete a measure_measure" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        let(:user) { FactoryBot.create(:user, :coordinator) }

        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will not allow you to delete a measure_measure" do
            expect(subject).to be_forbidden
          end
        end

        context "with a measure_measure belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure, created_by: user)
          end

          it "will allow you to delete a measure_measure" do
            expect(subject).to be_no_content
          end
        end
      end

      context "as an admin" do
        let(:user) { FactoryBot.create(:user, :admin) }

        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will allow you to delete a measure_measure" do
            expect(subject).to be_no_content
          end
        end

        context "with a measure_measure belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: main_measure.measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure, created_by: user)
          end

          it "will allow you to delete a measure_measure" do
            expect(subject).to be_no_content
          end
        end
      end
    end
  end
end

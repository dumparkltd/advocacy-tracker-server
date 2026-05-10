require "rails_helper"
require "json"

RSpec.describe MeasureMeasuresController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:coordinator) { FactoryBot.create(:user, :coordinator) }
  let(:manager) { FactoryBot.create(:user, :manager) }
  let(:analyst) { FactoryBot.create(:user, :analyst) }
  let(:guest) { FactoryBot.create(:user) }

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
    let(:measure_measure) do
      main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
      other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
      FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
    end

    subject { get :show, params: {id: measure_measure}, format: :json }

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
          measure_measure: {
            measure_id: regular_measure.id,
            other_measure_id: regular_measure.id
          }
        }
      end

      it "not allow creating a measure_measure" do
        post :create, format: :json, params: params
        expect(response).to be_unauthorized
      end
    end

    context "when signed in" do
      it "will not allow a guest to create a measure_measure" do
        sign_in guest
        post :create, format: :json, params: {
          measure_measure: {
            measure_id: regular_measure.id,
            other_measure_id: regular_measure.id
          }
        }
        expect(response).to be_forbidden
      end

      it "will not allow an analyst to create a measure_measure" do
        sign_in analyst
        post :create, format: :json, params: {
          measure_measure: {
            measure_id: regular_measure.id,
            other_measure_id: regular_measure.id
          }
        }
        expect(response).to be_forbidden
      end

      context "with regular measures" do
        let(:another_regular_measure) do
          FactoryBot.create(:measure,
            measuretype: regular_measuretype,
            draft: false)
        end

        let(:params) do
          {
            measure_measure: {
              measure_id: regular_measure.id,
              other_measure_id: another_regular_measure.id
            }
          }
        end

        subject { post :create, format: :json, params: params }

        it "will allow a manager to create a measure_measure" do
          sign_in manager
          expect(subject).to be_created
        end

        it "will allow a coordinator to create a measure_measure" do
          sign_in coordinator
          expect(subject).to be_created
        end

        it "will allow an admin to create a measure_measure" do
          sign_in admin
          expect(subject).to be_created
        end
      end

      it "will return an error if params are incorrect" do
        sign_in manager
        # Provide valid measure IDs but invalid other attributes
        post :create, format: :json, params: {
          measure_measure: {
            measure_id: regular_measure.id,
            other_measure_id: regular_measure.id  # Same measure - should fail validation
          }
        }
        expect(response).to have_http_status(422)
      end
    end

    context "with published statement" do
      let(:params) do
        {
          measure_measure: {
            measure_id: published_statement.id,
            other_measure_id: regular_measure.id
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
          measure_measure: {
            measure_id: unpublished_statement.id,
            other_measure_id: regular_measure.id
          }
        }
      end

      subject { post :create, format: :json, params: params }

      it "will allow manager to create relationship" do
        sign_in manager
        expect(subject).to be_created
      end
    end

    context "with published statement as other_measure" do
      let(:params) do
        {
          measure_measure: {
            measure_id: regular_measure.id,
            other_measure_id: published_statement.id
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
    end

    context "with both measures published" do
      let(:another_published_statement) do
        FactoryBot.create(:measure,
          measuretype: statement_measuretype,
          public_api: true,
          is_official: true,
          is_archive: false,
          private: false,
          draft: false)
      end

      let(:params) do
        {
          measure_measure: {
            measure_id: published_statement.id,
            other_measure_id: another_published_statement.id
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

      context "as admin" do
        it "will allow creating relationship" do
          sign_in admin
          expect(subject).to be_created
        end
      end
    end
  end

  describe "Delete destroy" do

    context "when signed in" do
      let(:delete_request) { delete :destroy, format: :json, params: {id: measure_measure} }

      context "as a guest" do
        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will not allow you to delete a measure_measure" do
            sign_in guest
            expect(delete_request).to be_forbidden
          end
        end

        context "with a measure_measure belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure, created_by: guest)
          end

          it "will not allow you to delete a measure_measure" do
            sign_in guest
            expect(delete_request).to be_forbidden
          end
        end
      end

      context "as an analyst" do
        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will not allow you to delete a measure_measure" do
            sign_in analyst
            expect(delete_request).to be_forbidden
          end
        end
      end

      context "as a manager" do
        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will allow you to delete a measure_measure" do
            sign_in manager
            expect(delete_request).to be_no_content
          end
        end
      end

      context "as a coordinator" do
        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will allow you to delete a measure_measure" do
            sign_in coordinator
            expect(delete_request).to be_no_content
          end
        end
      end

      context "as an admin" do
        context "with a measure_measure not belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure)
          end

          it "will allow you to delete a measure_measure" do
            sign_in admin
            expect(delete_request).to be_no_content
          end
        end

        context "with a measure_measure belonging to the signed in user" do
          let(:measure_measure) do
            main_measure = FactoryBot.create(:measure, measuretype: statement_measuretype)
            other_measure = FactoryBot.create(:measure, measuretype: regular_measuretype)
            FactoryBot.create(:measure_measure, measure: main_measure, other_measure: other_measure, created_by: admin)
          end

          it "will allow you to delete a measure_measure" do
            sign_in admin
            expect(delete_request).to be_no_content
          end
        end
      end

      context "with published statement" do
        let(:measure_measure) do
          FactoryBot.create(:measure_measure,
            measure: published_statement,
            other_measure: regular_measure)
        end

        subject { delete :destroy, format: :json, params: {id: measure_measure.id} }

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
        let(:measure_measure) do
          FactoryBot.create(:measure_measure,
            measure: unpublished_statement,
            other_measure: regular_measure,
            created_by_id: manager.id)
        end

        subject { delete :destroy, format: :json, params: {id: measure_measure.id} }

        it "will allow manager who created to delete relationship" do
          sign_in manager
          expect(subject).to be_no_content
        end
      end
    end
  end
end

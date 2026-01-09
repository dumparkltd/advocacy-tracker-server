require "rails_helper"

RSpec.describe UserMeasureMailer, type: :mailer do
  describe "created" do
    let(:measure) { FactoryBot.create(:measure, :published) }
    let(:user_measure) { FactoryBot.create(:user_measure, measure: measure) }
    let(:mail) { UserMeasureMailer.created(user_measure) }

    describe "with a measure that has notifications disabled" do
      let(:measure) { FactoryBot.create(:measure, notifications: false) }

      it "does not send an email" do
        expect(mail.body).to be_blank
        expect(mail.from).to be_nil
        expect(mail.subject).to be_nil
        expect(mail.to).to be_nil
      end
    end

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("user_measure_mailer.created.subject", measuretype: user_measure.measure.measuretype.title.downcase))
      expect(mail.to).to eq([user_measure.user.email])
      expect(mail.from).to eq(%w[plasticpolicy@wwf.no])
      expect(mail[:from].display_names).to include("Global Plastic Policy Team")
    end

    it "mentions the user's name" do
      expect(mail.body.encoded).to match(user_measure.user.name)
    end

  end

  describe "task_updated" do
    let(:measure) { FactoryBot.create(:measure, :published) }
    let(:user_measure) { FactoryBot.create(:user_measure, measure: measure) }
    let(:mail) { UserMeasureMailer.task_updated(user_measure) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("user_measure_mailer.task_updated.subject", measuretype: user_measure.measure.measuretype.title.downcase))
      expect(mail.to).to eq([user_measure.user.email])
      expect(mail.from).to eq(%w[plasticpolicy@wwf.no])
    end
  end
end

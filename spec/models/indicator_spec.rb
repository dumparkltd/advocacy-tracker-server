require "rails_helper"

RSpec.describe Indicator, type: :model do
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to have_many :measures }
  it { is_expected.to have_many :categories }

  it "is expected to default private to false" do
    expect(subject.private).to eq(false)
  end

  describe 'public_api validations' do
    describe 'public_api state requirements' do
      it 'allows public_api when all conditions are false' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: false, draft: false)
        expect(indicator).to be_valid
      end

      it 'rejects public_api when archived' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: true, private: false, draft: false)
        expect(indicator).not_to be_valid
      end

      it 'rejects public_api when confidential' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: true, draft: false)
        expect(indicator).not_to be_valid
      end

      it 'rejects public_api when draft' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: false, draft: true)
        expect(indicator).not_to be_valid
      end
    end

    describe 'bidirectional validation errors' do
      it 'shows error on is_archive when trying to archive public record' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: true, private: false, draft: false)
        expect(indicator).not_to be_valid
      end

      it 'shows error on private when trying to make public record confidential' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: true, draft: false)
        expect(indicator).not_to be_valid
      end

      it 'shows error on draft when trying to draft public record' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: false, draft: true)
        expect(indicator).not_to be_valid
      end

      it 'shows errors on both fields when both are set to conflicting values' do
        indicator = FactoryBot.build(:indicator, public_api: true, is_archive: true, private: false, draft: false)
        expect(indicator).not_to be_valid
        expect(indicator.errors[:public_api]).to be_present
        expect(indicator.errors[:is_archive]).to be_present
      end
    end
  end
  describe '#publicly_accessible?' do
    it 'returns true when all conditions met' do
      indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: false, draft: false)
      expect(indicator.publicly_accessible?).to eq(true)
    end

    it 'returns false when not public_api' do
      indicator = FactoryBot.build(:indicator, public_api: false, is_archive: false, private: false, draft: false)
      expect(indicator.publicly_accessible?).to eq(false)
    end

    it 'returns false when archived' do
      indicator = FactoryBot.build(:indicator, public_api: true, is_archive: true, private: false, draft: false)
      expect(indicator.publicly_accessible?).to eq(false)
    end

    it 'returns false when confidential' do
      indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: true, draft: false)
      expect(indicator.publicly_accessible?).to eq(false)
    end

    it 'returns false when draft' do
      indicator = FactoryBot.build(:indicator, public_api: true, is_archive: false, private: false, draft: true)
      expect(indicator.publicly_accessible?).to eq(false)
    end
  end

end

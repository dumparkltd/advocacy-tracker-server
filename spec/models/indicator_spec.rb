require "rails_helper"

RSpec.describe Indicator, type: :model do
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to have_many :measures }
  it { is_expected.to have_many :categories }
  it { is_expected.to belong_to(:parent).class_name('Indicator').optional }
  it { is_expected.to have_many(:children).class_name('Indicator').with_foreign_key('parent_id').dependent(:nullify) }


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

  context "Parent-child relation validations" do
    it "Can't be its own parent" do
      indicator = FactoryBot.create(:indicator)
      indicator.update(parent_id: indicator.id)
      expect(indicator).to be_invalid
      expect(indicator.errors[:parent_id]).to include("cannot reference itself")
    end

    it "Should not update parent_id if parent is already a child-indicator" do
      parent_indicator = FactoryBot.create(:indicator, :parent_indicator)
      child_indicator = FactoryBot.create(:indicator, :child_indicator, parent: parent_indicator)
      grandchild_indicator = FactoryBot.build(:indicator, :child_indicator, parent: child_indicator)

      expect(grandchild_indicator).to be_invalid
      expect(grandchild_indicator.errors[:parent_id]).to include("cannot have a grandparent (maximum 2 levels allowed)")
    end
  end

  describe 'scopes' do
    let!(:root1) { FactoryBot.create(:indicator, parent: nil) }
    let!(:root2) { FactoryBot.create(:indicator, parent: nil) }
    let!(:child1) { FactoryBot.create(:indicator, parent: root1) }
    let!(:child2) { FactoryBot.create(:indicator, parent: root1) }
    let!(:child3) { FactoryBot.create(:indicator, parent: root2) }

    describe '.root_indicators' do
      it 'returns only indicators without parents' do
        expect(Indicator.root_indicators).to contain_exactly(root1, root2)
      end
    end

    describe '.child_indicators' do
      it 'returns only indicators with parents' do
        expect(Indicator.child_indicators).to contain_exactly(child1, child2, child3)
      end
    end

    describe '.parent_indicators' do
      it 'returns only indicators that have children' do
        expect(Indicator.parent_indicators).to contain_exactly(root1, root2)
      end

      it 'excludes indicators without children' do
        childless = FactoryBot.create(:indicator, parent: nil)
        expect(Indicator.parent_indicators).not_to include(childless)
      end
    end
  end

  describe 'dependent behavior' do
    let(:parent_indicator) { FactoryBot.create(:indicator) }
    let!(:child1) { FactoryBot.create(:indicator, parent: parent_indicator) }
    let!(:child2) { FactoryBot.create(:indicator, parent: parent_indicator) }

    it 'nullifies children when parent is destroyed' do
      parent_indicator.destroy
      expect(child1.reload.parent_id).to be_nil
      expect(child2.reload.parent_id).to be_nil
    end

    it 'does not destroy children when parent is destroyed' do
      child1_id = child1.id
      child2_id = child2.id

      parent_indicator.destroy

      expect(Indicator.exists?(child1_id)).to be true
      expect(Indicator.exists?(child2_id)).to be true
    end
  end
end

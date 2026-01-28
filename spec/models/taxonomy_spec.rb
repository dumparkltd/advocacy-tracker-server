require "rails_helper"

RSpec.describe Taxonomy, type: :model do
  it { is_expected.to validate_presence_of :title }
  # shoulda-matchers deprecation: not possible to fully test this
  # it { is_expected.to validate_inclusion_of(:allow_multiple).in_array([true, false]) }
  # shoulda-matchers deprecation: not possible to fully test this
  # it { is_expected.to validate_inclusion_of(:tags_measures).in_array([true, false]) }

  it { is_expected.to have_many(:categories) }
  it { is_expected.to belong_to(:taxonomy).optional }
  it { is_expected.to have_many :taxonomies }

  it { is_expected.to have_many(:categories) }

  context "Sub-relation validations" do
    it "Should update parent_id" do
      taxonomy = FactoryBot.create(:taxonomy)
      sub_taxonomy = FactoryBot.create(:taxonomy)
      sub_taxonomy.parent_id = taxonomy.id
      sub_taxonomy.save!
    end

    it "Should not update parent_id if parent is already a sub-taxonomy" do
      sub_taxonomy = FactoryBot.create(:taxonomy)
      taxonomy = FactoryBot.create(:taxonomy, :sub_taxonomy)
      sub_taxonomy.parent_id = taxonomy.id
      expect(sub_taxonomy).to be_invalid
      expect(sub_taxonomy.errors[:parent_id]).to include("Parent taxonomy is already a sub-taxonomy")
    end

    it "Can't be its own parent" do
      taxonomy = FactoryBot.create(:taxonomy)
      taxonomy.update(parent_id: taxonomy.id)
      expect(taxonomy).to be_invalid
      expect(taxonomy.errors[:parent_id]).to include("Taxonomy can't be its own parent")
    end

    it "is expected to cascade destroy dependent relationships" do
      taxonomy = FactoryBot.create(:measuretype_taxonomy).taxonomy
      FactoryBot.create(:actortype_taxonomy, taxonomy: taxonomy)

      expect { taxonomy.destroy }.to change {
        [
          Taxonomy.count,
          MeasuretypeTaxonomy.count,
          ActortypeTaxonomy.count
        ]
      }.from([1, 1, 1]).to([0, 0, 0])
    end
  end
end

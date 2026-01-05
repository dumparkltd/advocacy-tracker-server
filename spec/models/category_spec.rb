require "rails_helper"

RSpec.describe Category, type: :model do
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to belong_to :taxonomy }
  it { is_expected.to belong_to(:manager).optional }
  it { is_expected.to belong_to(:category).optional }
  it { is_expected.to have_many :users }
  it { is_expected.to have_many :measures }
  it { is_expected.to have_many :indicators }
  it { is_expected.to have_many :categories }

  it "is expected to default private to false" do
    expect(subject.private).to eq(false)
  end

  context "Sub-relation validations" do
    it "Should update parent_id with correct taxonomy relation" do
      category = FactoryBot.create(:category, :parent_category)
      sub_category = FactoryBot.create(:category, :sub_category)
      taxonomy = FactoryBot.create(:taxonomy, :sub_taxonomy)

      sub_category.taxonomy_id = taxonomy.id
      category.taxonomy_id = taxonomy.parent_id
      sub_category.save!
      category.save!

      sub_category.parent_id = category.id
      sub_category.save!
    end

    it "Should not update parent_id if parent is already a sub-category" do
      category = FactoryBot.create(:category)
      parent_category = FactoryBot.create(:category, :parent_category)
      sub_category = FactoryBot.create(:category, :sub_category)
      taxonomy = FactoryBot.create(:taxonomy, :sub_taxonomy)

      parent_category.taxonomy_id = taxonomy.id
      category.taxonomy_id = taxonomy.parent_id
      category.save!

      parent_category.parent_id = category.id
      parent_category.save!

      sub_category.parent_id = parent_category.id
      expect(sub_category).to be_invalid
      expect(sub_category.errors[:parent_id]).to include("Parent category is already a sub-category")
    end

    it "Should not update parent_id with incorrect taxonomy relation" do
      category = FactoryBot.create(:category, :parent_category)
      sub_category = FactoryBot.create(:category, :sub_category)
      sub_category.parent_id = category.id
      expect(sub_category).to be_invalid
      expect(sub_category.errors[:parent_id]).to include("Taxonomy does not have parent category's taxonomy as parent")
    end

    it "Can't be its own parent" do
      category = FactoryBot.create(:category)
      category.update(parent_id: category.id)
      expect(category).to be_invalid
      expect(category.errors[:parent_id]).to include("Category can't be its own parent")
    end

    it "is expected to cascade destroy dependent relationships" do
      actor = FactoryBot.create(:actor)
      taxonomy = FactoryBot.create(:taxonomy, actortype_ids: [actor.actortype_id], measuretypes: [FactoryBot.create(:measuretype)])

      category = FactoryBot.create(:category, taxonomy: taxonomy)
      FactoryBot.create(:actor_category, actor: actor, category: category)
      FactoryBot.create(:user_category, category: category)

      FactoryBot.create(:measure_category,
        category: category,
        measure: FactoryBot.create(:measure, measuretype: category.taxonomy.measuretypes.first))

      expect { category.destroy }.to change {
        [
          Category.count,
          ActorCategory.count,
          UserCategory.count,
          MeasureCategory.count
        ]
      }.from([1, 1, 1, 1]).to([0, 0, 0, 0])
    end
  end
end

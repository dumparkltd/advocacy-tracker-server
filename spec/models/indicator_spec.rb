require "rails_helper"

RSpec.describe Indicator, type: :model do
  it { is_expected.to validate_presence_of :title }
  it { is_expected.to have_many :measures }
  it { is_expected.to have_many :categories }

  it "is expected to default private to false" do
    expect(subject.private).to eq(false)
  end
end

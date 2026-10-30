# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::Digital do
  context "validation" do
    it { is_expected.to belong_to(:variant) }

    it "protects only PDFs" do
      expect(build(:digital, drm: true)).not_to be_valid
      expect(build(:digital, :drm)).to be_valid
    end
  end

  describe "#destroy" do
    it "destroys associated digital_links" do
      digital = create(:digital)
      3.times { digital.digital_links.create!(line_item: create(:line_item)) }
      expect(Spree::DigitalLink.count).to eq(3)
      expect {
        digital.destroy
      }.to change(Spree::DigitalLink, :count).by(-3)
    end
  end
end

RSpec.describe SolidusDigital::PermissionSets::DigitalManagement do
  it "names its privilege and category for the role editor" do
    expect([described_class.privilege, described_class.category]).to eq([:management, :digital])
    expect([SolidusDigital::PermissionSets::DigitalDisplay.privilege, SolidusDigital::PermissionSets::DigitalDisplay.category]).to eq([:display, :digital])
  end
end

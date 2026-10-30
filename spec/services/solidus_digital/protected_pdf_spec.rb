# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusDigital::ProtectedPdf do
  let(:digital) { create(:digital, :drm) }
  let(:order) { create(:order_ready_to_ship, line_items_attributes: [{variant: digital.variant}]) }

  it "inserts the license page after the cover and allows printing only" do
    output = Tempfile.new(["protected", ".pdf"])
    described_class.new(digital.attachment, order.line_items.first).call(output.path)
    pdf = File.binread(output.path)

    expect(SolidusDigital::TestingSupport.pdf_pages(pdf)).to match([
      include("Cover"),
      include("This copy is licensed to you", "Licensed to: #{order.email}", "Order: #{order.number}"),
      include("Chapter 1")
    ])
    Dir.mktmpdir do |dir|
      File.binwrite("#{dir}/protected.pdf", pdf)
      encryption = `qpdf --show-encryption #{dir}/protected.pdf`
      expect(encryption).to include("R = 6", "print high resolution: allowed", "extract for any purpose: not allowed", "modify anything: not allowed")
    end
  end
end

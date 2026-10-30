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
  it "uses inherited page boxes and rotation for the license page" do
    source = Prawn::Document.new(page_size: [500, 700])
    source.text "Cover"
    page = source.state.page.dictionary.data
    source.state.store.pages.data.merge!(MediaBox: page.delete(:MediaBox), CropBox: page.delete(:CropBox), Rotate: 90)
    digital.attachment.attach(io: StringIO.new(source.render), filename: "inherited.pdf", content_type: "application/pdf")

    Tempfile.create(["protected", ".pdf"]) do |output|
      described_class.new(digital.attachment, order.line_items.first).call(output.path)
      license = PDF::Reader.new(output.path).pages[1]
      expect(license.attributes.fetch(:MediaBox)).to eq([0, 0, 700, 500])
    end
  end
end

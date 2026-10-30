# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusDigital::DeliverDigitalsJob do
  let(:digital_variant) { create(:variant, digitals: [create(:digital)]) }

  def links(order) = order.line_items.flat_map(&:digital_links)

  it "e-mails the download links, then ships the digital shipment without the shipped e-mail" do
    order = create(:order_ready_to_ship, line_items_attributes: [{variant: digital_variant, quantity: 2}])
    allow(Spree::Bus).to receive(:publish).and_call_original
    perform_enqueued_jobs { described_class.perform_now(order) }
    expect(Spree::Bus).to have_received(:publish).with(:digital_links_created, order: order)

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq([order.email])
    expect(links(order).size).to eq(2)
    links(order).each { |link| expect(mail.html_part.body.decoded).to include("https://shop.example.com/digital/#{link.secret}") }
    expect(order.reload.shipments.map(&:state)).to eq(["shipped"])
  end

  it "keeps links when it runs again and leaves shipments with physical items ready" do
    order = create(:order_ready_to_ship, line_items_attributes: [{variant: digital_variant}, {variant: create(:variant)}])
    described_class.perform_now(order)
    secrets = links(order).map(&:secret)
    described_class.perform_now(order.reload)

    expect(links(order.reload).map(&:secret)).to eq(secrets)
    expect(order.shipments.map(&:state)).to eq(["ready"])
  end

  it "leaves the e-mail and shipping to the store when core e-mails are off" do
    stub_spree_preferences(send_core_emails: false)
    order = create(:order_ready_to_ship, line_items_attributes: [{variant: digital_variant}])
    allow(Spree::Bus).to receive(:publish).and_call_original
    described_class.perform_now(order)
    expect(Spree::Bus).to have_received(:publish).with(:digital_links_created, order: order)

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(order.reload.shipments.map(&:state)).to eq(["ready"])
  end

  it "does nothing for unpaid orders" do
    order = create(:completed_order_with_totals, line_items_attributes: [{variant: digital_variant}])
    described_class.perform_now(order)

    expect(links(order)).to be_empty
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end

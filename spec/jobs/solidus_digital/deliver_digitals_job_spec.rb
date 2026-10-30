# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusDigital::DeliverDigitalsJob do
  let(:digital_variant) { create(:variant, digitals: [create(:digital)]) }

  it "e-mails the download links, then ships the digital shipment without the shipped e-mail" do
    order = create(:order_ready_to_ship, line_items_attributes: [{variant: digital_variant, quantity: 2}])
    perform_enqueued_jobs { described_class.perform_now(order) }

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq([order.email])
    order.digital_links.each { |link| expect(mail.html_part.body.decoded).to include("https://shop.example.com/digital/#{link.secret}") }
    expect(order.digital_links.size).to eq(2)
    expect(order.reload.shipments.map(&:state)).to eq(["shipped"])
  end

  it "keeps links when it runs again and leaves shipments with physical items ready" do
    order = create(:order_ready_to_ship, line_items_attributes: [{variant: digital_variant}, {variant: create(:variant)}])
    described_class.perform_now(order)
    secrets = order.digital_links.map(&:secret)
    described_class.perform_now(order.reload)

    expect(order.reload.digital_links.map(&:secret)).to eq(secrets)
    expect(order.shipments.map(&:state)).to eq(["ready"])
  end

  it "does nothing for unpaid orders" do
    order = create(:completed_order_with_totals, line_items_attributes: [{variant: digital_variant}])
    described_class.perform_now(order)

    expect(order.digital_links).to be_empty
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end

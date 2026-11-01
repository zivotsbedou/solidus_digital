# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::Order do
  let(:digital_variant) { create(:variant, digitals: [create(:digital)]) }
  let(:physical_variant) { create(:variant) }

  # Mirrors a paid order whose digital items went out in their own shipment.
  def paid_order_with_shipped_digitals
    order = create(:order_ready_to_ship, line_items_attributes: [{variant: digital_variant}, {variant: physical_variant}])
    physical_units = order.inventory_units.select { |unit| unit.variant == physical_variant }
    shipment = order.shipments.create!(stock_location: order.shipments.first.stock_location, state: "ready")
    physical_units.each { |unit| unit.update!(shipment:) }
    shipment.shipping_rates.create!(shipping_method: order.shipments.first.shipping_method, cost: 0, selected: true)
    SolidusDigital::DeliverDigitalsJob.perform_now(order.reload)
    order.reload
  end

  it "cancels a paid order whose only shipped shipment is digital" do
    order = paid_order_with_shipped_digitals
    digital, physical = order.shipments.partition { |shipment| shipment.line_items.all?(&:digital?) }.map(&:sole)
    link = order.line_items.flat_map(&:digital_links).sole
    expect(digital).to be_shipped
    expect(link).to be_authorizable

    allow(Spree::Bus).to receive(:publish).and_call_original
    expect { order.canceled_by(create(:admin_user)) }.to change { physical_variant.stock_items.sum(:count_on_hand) }.by(1)

    expect(order.reload).to be_canceled
    expect(physical.reload).to be_canceled
    expect(digital.reload).to be_shipped
    expect(link.reload).not_to be_authorizable
    expect(Spree::Bus).to have_received(:publish).with(:order_canceled, order:)
  end

  it "keeps an order with a shipped physical shipment uncancelable" do
    order = create(:shipped_order, line_items_attributes: [{variant: digital_variant}, {variant: physical_variant}])

    expect(order).not_to be_allow_cancel
  end
end

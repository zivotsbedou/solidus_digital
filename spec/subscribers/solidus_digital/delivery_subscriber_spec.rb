# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusDigital::DeliverySubscriber do
  let(:digital_variant) { create(:variant, digitals: [create(:digital)]) }

  it "delivers once a later captured payment makes the order paid" do
    order = create(:completed_order_with_totals, line_items_attributes: [{variant: digital_variant}])
    payment = create(:check_payment, order: order, amount: order.total, state: "pending")

    expect { order.recalculate }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
    expect { payment.capture! }.to have_enqueued_job(SolidusDigital::DeliverDigitalsJob).with(order).exactly(:once)
    expect { order.recalculate }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
  end

  it "delivers orders that are paid when checkout completes, such as free ones" do
    order = create(:order_ready_to_complete, line_items_attributes: [{variant: digital_variant, price: 0}], shipment_cost: 0, payment_type: :check_payment)

    expect { order.complete! }.to have_enqueued_job(SolidusDigital::DeliverDigitalsJob).with(order).exactly(:once)
    expect(order).to be_paid
  end

  it "ignores unpaid orders and paid orders without digital items" do
    unpaid = create(:order_ready_to_complete, line_items_attributes: [{variant: digital_variant}], payment_type: :check_payment)
    physical = create(:completed_order_with_totals)
    physical_payment = create(:check_payment, order: physical, amount: physical.total, state: "pending")

    expect { unpaid.complete! }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
    expect { physical_payment.capture! }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
  end
end

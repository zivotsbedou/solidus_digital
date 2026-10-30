# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusDigital::DeliverySubscriber do
  let(:digital_variant) { create(:variant, digitals: [create(:digital)]) }
  let(:order) { create(:completed_order_with_totals, line_items_attributes: [{ variant: digital_variant }]) }
  let!(:payment) { create(:check_payment, order: order, amount: order.total, state: 'pending') }

  it 'delivers once the captured payment makes the order paid' do
    expect { order.recalculate }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
    expect { payment.capture! }.to have_enqueued_job(SolidusDigital::DeliverDigitalsJob).with(order).exactly(:once)
    expect { order.recalculate }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
  end

  it 'ignores paid orders without digital items' do
    physical = create(:completed_order_with_totals)
    physical_payment = create(:check_payment, order: physical, amount: physical.total, state: 'pending')
    expect { physical_payment.capture! }.not_to have_enqueued_job(SolidusDigital::DeliverDigitalsJob)
  end
end

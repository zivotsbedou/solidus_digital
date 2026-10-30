# frozen_string_literal: true

module SolidusDigital
  # Delivers digital items once the order is paid: at checkout when the payment
  # is captured there, or later when a captured payment makes the order paid
  # (bank transfers, manual capture in the admin).
  class DeliverySubscriber
    include Omnes::Subscriber

    handle :order_finalized, with: :order_finalized, id: :solidus_digital_deliver_finalized_order
    handle :order_recalculated, with: :order_recalculated, id: :solidus_digital_deliver_recalculated_order

    def order_finalized(event)
      deliver(event[:order])
    end

    # One capture recalculates the order several times; act only on the change to paid.
    def order_recalculated(event)
      order = event[:order]
      deliver(order) unless Spree::Order.new(payment_state: order.payment_state_before_last_save).paid?
    end

    private

    def deliver(order)
      return unless order.paid? && order.line_items.any?(&:digital?)

      # Payments are often captured inside a transaction; enqueue once it commits.
      ActiveRecord.after_all_transactions_commit { DeliverDigitalsJob.perform_later(order) }
    end
  end
end

# frozen_string_literal: true

module SolidusDigital
  # Delivers digital items once a captured payment makes the order paid, so
  # orders paid later (bank transfers, manual capture) get their links too.
  class DeliverySubscriber
    include Omnes::Subscriber

    PAID_STATES = %w[paid credit_owed].freeze

    handle :order_recalculated, with: :deliver_digitals, id: :solidus_digital_deliver_digitals

    def deliver_digitals(event)
      order = event[:order]
      return if PAID_STATES.include?(order.payment_state_before_last_save)
      return unless order.paid? && order.some_digital?

      DeliverDigitalsJob.perform_later(order)
    end
  end
end

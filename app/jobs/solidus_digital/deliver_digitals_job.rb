# frozen_string_literal: true

module SolidusDigital
  # Creates the download links of a paid order, e-mails them and then ships
  # the shipments that hold only digital items.
  class DeliverDigitalsJob < ActiveJob::Base
    # Payments are often captured inside a transaction; wait until it commits.
    self.enqueue_after_transaction_commit = true

    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(order)
      return unless order.paid?

      order.with_lock { order.digital_line_items.each(&:create_digital_links) }
      ::Spree::DigitalMailer.download_links(order).deliver_now
      order.shipments.select { |shipment| shipment.ready? && shipment.line_items.all?(&:digital?) }.each do |shipment|
        shipment.suppress_mailer = true
        shipment.ship!
      end
    end
  end
end

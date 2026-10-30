# frozen_string_literal: true

module SolidusDigital
  # Creates the download links of a paid order, e-mails them and then ships the
  # shipments that hold only digital items. Stores that turned off core e-mails
  # receive the digital_links_created event and send the links themselves.
  class DeliverDigitalsJob < ActiveJob::Base
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(order)
      return unless order.can_ship? && order.paid?

      line_items = order.line_items.select(&:digital?)
      order.with_lock { line_items.each { |line_item| Spree::DigitalLinksCreator.new(line_item).create_digital_links } }
      Spree::Bus.publish(:digital_links_created, order:)
      return unless Spree::Config.send_core_emails

      SolidusDigital.config.mailer_class.download_links_email(order).deliver_now
      order.shipments.select { |shipment| shipment.ready? && shipment.line_items.all?(&:digital?) }.each do |shipment|
        shipment.suppress_mailer = true
        shipment.ship!
      end
    end
  end
end

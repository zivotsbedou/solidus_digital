# frozen_string_literal: true

module SolidusDigital
  # Paying ships digital-only shipments at once, which would leave a paid order
  # with physical items uncancelable. Staff may still cancel it while only
  # digital shipments have shipped; the links stop working with the order.
  module OrderPatch
    def allow_cancel?
      return true if super
      return false unless completed? && !canceled?

      shipped, unshipped = shipments.partition(&:shipped?)
      shipped.any? && shipped.all? { |shipment| shipment.line_items.all?(&:digital?) } &&
        unshipped.all? { |shipment| shipment.can_cancel? }
    end

    def cancel_shipments!
      shipments.reject(&:shipped?).each(&:cancel!)
    end

    Spree::Order.prepend self
  end
end

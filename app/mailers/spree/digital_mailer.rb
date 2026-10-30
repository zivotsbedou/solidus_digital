# frozen_string_literal: true

module Spree
  class DigitalMailer < BaseMailer
    def download_links_email(order)
      @order = order
      @store = order.store
      @line_items = order.line_items.select(&:digital?)
      mail(to: order.email, from: from_address(@store), bcc: bcc_address(@store).presence,
        subject: t(".subject", store: @store.name, number: order.number))
    end
  end
end

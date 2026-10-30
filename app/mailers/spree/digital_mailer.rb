# frozen_string_literal: true

module Spree
  class DigitalMailer < BaseMailer
    def download_links(order)
      @order = order
      @store = order.store
      mail(to: order.email, from: from_address(@store), bcc: bcc_address(@store).presence,
        subject: t('.subject', store: @store.name, number: order.number))
    end
  end
end

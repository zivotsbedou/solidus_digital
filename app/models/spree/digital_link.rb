# frozen_string_literal: true

module Spree
  class DigitalLink < Spree::Base
    belongs_to :digital
    belongs_to :line_item

    has_secure_token :secret, length: 30, on: :initialize

    validates :digital, presence: true
    validates :secret, length: {is: 30}
    before_validation :set_defaults, on: :create

    delegate :attachment, to: :digital

    # Gives every link of the order a fresh period and download count, then e-mails them again.
    def self.resend(order)
      joins(:line_item).where(spree_line_items: {order_id: order.id}).find_each(&:reset!)
      SolidusDigital.config.mailer_class.download_links_email(order).deliver_later
    end

    # A link works while its order entitles the buyer to it, within the configured days and downloads.
    def authorizable?
      resendable? && attachment.attached? && !expired? && !access_limit_exceeded?
    end

    # The order can ship and stays paid, so the buyer may get fresh links.
    def resendable?
      order = line_item.order
      order.can_ship? && order.paid?
    end

    def expired?
      created_at <= SolidusDigital.config.authorized_days.days.ago
    end

    def access_limit_exceeded?
      return false if SolidusDigital.config.authorized_clicks.nil?

      access_counter >= SolidusDigital.config.authorized_clicks
    end

    # This method should be called when a download is initiated.
    # It returns +true+ or +false+ depending on whether the authorization is granted.
    def authorize!
      (authorizable? && increment!(:access_counter)) ? true : false
    end

    def reset!
      update_columns(access_counter: 0, created_at: Time.current)
    end

    private

    # Zero the access_counter, otherwise it might turn out to be NULL.
    def set_defaults
      self.access_counter ||= 0
    end
  end
end

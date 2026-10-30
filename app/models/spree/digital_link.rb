# frozen_string_literal: true

module Spree
  class DigitalLink < Spree::Base
    belongs_to :digital
    belongs_to :line_item

    validates :digital, presence: true
    validates :secret, length: {is: 30}
    before_validation :set_defaults, on: :create

    delegate :attachment, to: :digital

    # A link works while its order stays paid, within the configured days and downloads.
    def authorizable?
      line_item.order.paid? && attachment.attached? && !expired? && !access_limit_exceeded?
    end

    def expired?
      created_at <= Spree::DigitalConfiguration[:authorized_days].days.ago
    end

    def access_limit_exceeded?
      return false if Spree::DigitalConfiguration[:authorized_clicks].nil?

      access_counter >= Spree::DigitalConfiguration[:authorized_clicks]
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

    # Populating the secret automatically and zero'ing the access_counter (otherwise it might turn out to be NULL)
    def set_defaults
      self.secret = SecureRandom.hex(15)
      self.access_counter ||= 0
    end
  end
end

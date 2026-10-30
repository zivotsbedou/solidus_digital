# frozen_string_literal: true

module SolidusDigital
  module LineItemPatch
    def self.prepended(base)
      base.has_many :digital_links, class_name: "Spree::DigitalLink", dependent: :destroy
    end

    def digital?
      variant.digital? || variant.product.master.digital?
    end

    Spree::LineItem.prepend self
  end
end

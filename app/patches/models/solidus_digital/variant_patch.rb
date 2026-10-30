# frozen_string_literal: true

module SolidusDigital
  module VariantPatch
    def self.prepended(base)
      base.has_many :digitals, class_name: "Spree::Digital"
      base.after_discard :discard_digitals
    end

    # Is this variant to be downloaded by the customer?
    def digital?
      digitals.present?
    end

    private

    def discard_digitals
      digitals.each(&:destroy) unless SolidusDigital.config.keep_digitals
    end

    Spree::Variant.prepend self
  end
end

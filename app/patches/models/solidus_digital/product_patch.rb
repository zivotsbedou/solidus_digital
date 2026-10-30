# frozen_string_literal: true

module SolidusDigital
  module ProductPatch
    def self.prepended(base)
      base.has_many :digitals, through: :variants_including_master
    end

    Spree::Product.prepend self
  end
end

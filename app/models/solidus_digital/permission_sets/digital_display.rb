# frozen_string_literal: true

module SolidusDigital
  module PermissionSets
    class DigitalDisplay < ::Spree::PermissionSets::Base
      class << self
        def privilege
          :display
        end

        def category
          :digital
        end
      end

      def activate!
        can [:display, :admin], ::Spree::Digital
      end
    end
  end
end

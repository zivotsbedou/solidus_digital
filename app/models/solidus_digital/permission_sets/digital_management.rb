# frozen_string_literal: true

module SolidusDigital
  module PermissionSets
    class DigitalManagement < ::Spree::PermissionSets::Base
      class << self
        def privilege
          :management
        end

        def category
          :digital
        end
      end

      def activate!
        can :manage, ::Spree::Digital
      end
    end
  end
end

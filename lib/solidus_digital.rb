# frozen_string_literal: true

require "solidus_core"
require "solidus_support"
require "deface"
require "prawn"

require "solidus_digital/configuration"
require "solidus_digital/version"
require "solidus_digital/engine"

Spree::DigitalConfiguration = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
  SolidusDigital.config, "Spree::DigitalConfiguration is deprecated, use SolidusDigital.config", Spree.deprecator
)

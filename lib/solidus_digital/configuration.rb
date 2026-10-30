# frozen_string_literal: true

module SolidusDigital
  class Configuration < Spree::Preferences::Configuration
    # Downloads allowed per link; nil allows any number.
    preference :authorized_clicks, :integer, default: 3

    # Days a link works after it was created.
    preference :authorized_days, :integer, default: 2

    # Keep the files of discarded variants, so earlier buyers can still download them.
    preference :keep_digitals, :boolean, default: false

    # Links per line item: "quantity" or a fixed number.
    preference :digital_links_count, :string, default: "quantity"

    # Prawn font family for the license page of protected PDFs, e.g.
    # { normal: "Regular.ttf", bold: "Bold.ttf" }. The default PDF font only
    # covers Western European characters.
    preference :license_fonts, :hash, default: {}

    # Open downloads in the browser ("inline") or save them as files ("attachment").
    preference :disposition, :string, default: "attachment"

    class_name_attribute :mailer_class, default: "Spree::DigitalMailer"
    class_name_attribute :protected_pdf_class, default: "SolidusDigital::ProtectedPdf"
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    alias_method :config, :configuration

    def configure
      yield configuration
    end
  end
end

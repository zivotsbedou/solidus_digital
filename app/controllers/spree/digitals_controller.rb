# frozen_string_literal: true

module Spree
  class DigitalsController < Spree::BaseController
    before_action :load_link
    # Buyers can ask for fresh links themselves; the e-mail only goes to the order's address.
    rate_limit to: 1, within: 10.minutes, by: -> { params[:secret] }, with: :render_resent, only: :resend

    helper_method :masked_email

    def show
      # Standalone pages: storefront layouts need the app's own controller helpers.
      return render :unauthorized, status: :forbidden, layout: false unless @link.authorize!

      attachment = @link.attachment
      disposition = SolidusDigital.config.disposition
      response.headers["Cache-Control"] = "private, no-store"
      return redirect_to attachment.url(disposition:), allow_other_host: true unless @link.digital.drm?

      # The controller lives until the response is sent, so the file outlives send_file.
      @protected_pdf = Tempfile.new(["protected", ".pdf"], binmode: true)
      SolidusDigital.config.protected_pdf_class.new(attachment, @link.line_item).call(@protected_pdf.path)
      send_file @protected_pdf.path, filename: attachment.filename.to_s, type: attachment.content_type, disposition:
    end

    def resend
      return render :unauthorized, status: :forbidden, layout: false unless @link.resendable?

      DigitalLink.resend(@link.line_item.order)
      render_resent
    end

    private

    def load_link
      @link = DigitalLink.find_by!(secret: params[:secret])
    end

    def render_resent
      render :resent, layout: false
    end

    # Shows where the links went without revealing the address to whoever holds the link.
    def masked_email
      @link.line_item.order.email.sub(/\A(.)[^@]*/, '\1***')
    end
  end
end

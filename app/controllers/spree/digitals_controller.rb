# frozen_string_literal: true

module Spree
  class DigitalsController < Spree::BaseController
    def show
      link = DigitalLink.find_by!(secret: params[:secret])
      # A standalone error page: storefront layouts need the app's own controller helpers.
      return render :unauthorized, status: :forbidden, layout: false unless link.authorize!

      attachment = link.attachment
      response.headers["Cache-Control"] = "private, no-store"
      return redirect_to attachment.url(disposition: :attachment), allow_other_host: true unless link.digital.drm?

      # The controller lives until the response is sent, so the file outlives send_file.
      @protected_pdf = Tempfile.new(["protected", ".pdf"], binmode: true)
      SolidusDigital.config.protected_pdf_class.new(attachment, link.line_item).call(@protected_pdf.path)
      send_file @protected_pdf.path, filename: attachment.filename.to_s, type: attachment.content_type, disposition: "attachment"
    end
  end
end

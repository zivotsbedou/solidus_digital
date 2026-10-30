# frozen_string_literal: true

module Spree
  class DigitalsController < Spree::BaseController
    def show
      link = DigitalLink.find_by!(secret: params[:secret])
      return render :unauthorized, status: :forbidden unless link.authorize!

      attachment = link.attachment
      data = link.digital.drm? ? SolidusDigital::ProtectedPdf.new(attachment, link.line_item).call : attachment.download
      response.headers['Cache-Control'] = 'private, no-store'
      send_data data, filename: attachment.filename.to_s, type: attachment.content_type, disposition: 'attachment'
    end
  end
end

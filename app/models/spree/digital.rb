# frozen_string_literal: true

module Spree
  class Digital < Spree::Base
    belongs_to :variant
    has_many :digital_links, dependent: :destroy

    has_one_attached :attachment

    validates :attachment, presence: true
    validate :drm_requires_pdf

    private

    # Protected copies get a licence page and PDF encryption, which only PDFs support.
    def drm_requires_pdf
      errors.add(:drm, :pdf_only) if drm? && attachment.attached? && attachment.content_type != "application/pdf"
    end
  end
end

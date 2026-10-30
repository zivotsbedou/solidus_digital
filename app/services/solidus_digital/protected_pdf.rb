# frozen_string_literal: true

require "open3"

module SolidusDigital
  # Writes the buyer's copy of a PDF: a license page after the cover with the
  # order's e-mail and number, then AES-256 encryption that only allows printing.
  # Requires the qpdf command line tool. Replace it with
  # SolidusDigital.config.protected_pdf_class.
  class ProtectedPdf
    Error = Class.new(StandardError)

    def initialize(attachment, line_item)
      @attachment = attachment
      @order = line_item.order
    end

    def call(output)
      Dir.mktmpdir do |dir|
        @attachment.blob.open(tmpdir: dir) do |source|
          pages = JSON.parse(qpdf("--json=2", "--json-key=pages", source.path)).fetch("pages")
          license = File.join(dir, "license.pdf")
          File.binwrite(license, license_page(*page_size(source.path, pages.first.fetch("object"))))
          rest = (pages.size > 1) ? [".", "2-z"] : []
          qpdf source.path, "--pages", ".", "1", license, "1", *rest, "--",
            "--encrypt", "", SecureRandom.hex(16), "256", "--print=full", "--modify=none", "--extract=n", "--annotate=n", "--",
            output
        end
      end
    end

    private

    def page_size(path, object)
      attributes = {}
      visited = []
      while object
        raise Error, "Circular PDF page tree" if visited.include?(object)

        visited << object
        page = JSON.parse(qpdf("--json=2", "--json-key=qpdf", "--json-object=#{object}", path)).dig("qpdf", 1).values.first.fetch("value")
        attributes = page.slice("/CropBox", "/MediaBox", "/Rotate").merge(attributes)
        object = page["/Parent"]
      end
      x0, y0, x1, y1 = attributes["/CropBox"] || attributes.fetch("/MediaBox")
      size = [x1 - x0, y1 - y0]
      (attributes["/Rotate"].to_i % 180).zero? ? size : size.reverse
    end

    def license_page(width, height)
      pdf = Prawn::Document.new(page_size: [width, height], margin: 0)
      use_font(pdf)
      draw_lock(pdf, width / 2, height * 0.6)
      text = ->(key, **options) { I18n.t(key, scope: "spree.digitals.license", email: @order.email, number: @order.number, **options) }
      pdf.text_box text.call(:title), at: [60, height * 0.6 - 90], width: width - 120, align: :center, size: 22, style: :bold
      pdf.text_box text.call(:text), at: [110, height * 0.6 - 130], width: width - 220, align: :center, size: 12, leading: 4
      pdf.text_box "#{text.call(:licensed_to)}\n#{text.call(:order)}", at: [60, 90], width: width - 120, align: :center, size: 9, leading: 3
      pdf.render
    end

    def use_font(pdf)
      fonts = SolidusDigital.config.license_fonts.to_h.symbolize_keys.transform_values(&:to_s)
      return if fonts[:normal].blank?

      pdf.font_families.update("License" => {bold: fonts[:normal]}.merge(fonts))
      pdf.font "License"
    end

    def draw_lock(pdf, center_x, center_y)
      pdf.line_width 9
      pdf.stroke { pdf.curve [center_x - 24, center_y + 6], [center_x + 24, center_y + 6], bounds: [[center_x - 26, center_y + 62], [center_x + 26, center_y + 62]] }
      pdf.fill_rounded_rectangle [center_x - 40, center_y + 8], 80, 62, 8
      pdf.fill_color "ffffff"
      pdf.fill_circle [center_x, center_y - 16], 8
      pdf.fill_rectangle [center_x - 3, center_y - 18], 6, 18
      pdf.fill_color "000000"
    end

    def qpdf(*args)
      output, error, status = Open3.capture3("qpdf", *args)
      # Exit status 3 means qpdf wrote the file and only reported warnings.
      raise Error, "qpdf failed: #{error}" unless status.success? || status.exitstatus == 3

      output
    end
  end
end

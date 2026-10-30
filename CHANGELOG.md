# Changelog

## 2.0.0 (unreleased)

Breaking changes:

- Requires Solidus 4.8 or newer, Ruby 3.2 or newer and solidus_support 0.14.1
  or newer.
- Files are stored with Active Storage instead of Paperclip. Run
  `bin/rails solidus_digital:migrate_paperclip_files` after migrating; the
  Paperclip columns stay until a later release. The `spree_drm_records` table
  is dropped.
- Download links are created and e-mailed by
  `Spree::DigitalMailer#download_links_email` once the order is paid, instead
  of at checkout completion in an override of the stock confirmation e-mail.
- Configuration moved to `SolidusDigital.configure`; `Spree::DigitalConfiguration`
  is a deprecated alias and `s3_expiration_seconds` is gone.
- The "Digital Delivery" calculator and the digital stock splitter are gone;
  use a shipping category for digital products.
- The `Spree::Order` helpers (`digital?`, `some_digital?`, `digital_line_items`,
  `digital_links`, `reset_digital_links!`) and `Spree::DrmRecord` are gone.
- Resetting downloads is a `POST` to `/admin/orders/:order_id/digital_links/reset`
  and also e-mails the links again.
- Admin code loads only with solidus_backend; the gem now depends on deface.

Added:

- Orders paid later, such as bank transfers captured in the admin, get their
  links when the capture makes them paid.
- Links stop working when their order can no longer ship or is no longer paid.
- Shipments that hold only digital items are shipped after the e-mail, without
  the stock shipped e-mail.
- The `digital_links_created` event, for stores that send their own e-mails.
- Protected PDFs: a license page after the cover and print-only AES-256
  encryption, built per download with Prawn and qpdf.
- `mailer_class`, `protected_pdf_class` and `license_fonts` settings.
- GitHub Actions CI with solidusio/test-solidus-extension instead of CircleCI.

See https://github.com/solidusio-contrib/solidus_digital/releases or OLD_CHANGELOG.md for older versions.

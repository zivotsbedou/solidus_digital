# Changelog

## Unreleased

Breaking changes:

- Requires Solidus 4.8 or newer and Ruby 3.2 or newer.
- Files are stored with Active Storage instead of Paperclip. The migration
  removes the Paperclip columns and the `spree_drm_records` table; upload the
  files again after upgrading.
- Download links are created and e-mailed by `Spree::DigitalMailer` when a
  captured payment makes the order paid, instead of at checkout completion
  in an override of the stock confirmation e-mail.
- `Spree::DrmRecord` and the `s3_expiration_seconds` preference are gone.

Added:

- Links stop working when their order is no longer paid.
- Shipments that hold only digital items are shipped after the e-mail, without
  the stock shipped e-mail.
- Protected PDFs: a license page after the cover and print-only AES-256
  encryption, built per download with Prawn and qpdf.
- "Reset and resend digital downloads" also e-mails the links again.

See https://github.com/solidusio-contrib/solidus_digital/releases or OLD_CHANGELOG.md for older versions.

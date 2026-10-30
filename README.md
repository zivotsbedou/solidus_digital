# solidus_digital

A [Solidus](https://solidus.io/) extension for downloadable products such as
e-books, music and video. This fork targets Solidus 4.8, Ruby 4 and Active
Storage.

## How it works

Attach one or more files to a product's master variant or to any variant in
the "Digital Versions" tab of the legacy admin (`solidus_backend`;
`solidus_admin` edits products only with its alpha features on). When an
order is paid, the extension creates download links for each digital line
item, publishes the `digital_links_created` event, e-mails the links with
`Spree::DigitalMailer#download_links_email` and ships the shipments that hold
only digital items, without the stock "shipped" e-mail. Orders paid at
checkout get their links when checkout completes; orders paid later, by bank
transfer or a manual capture in the admin, when the capture makes them paid.
Unpaid orders never get links. With `Spree::Config.send_core_emails` turned
off, the extension only publishes the event and leaves the e-mail and the
shipments to the store.

A link works while its order can ship and stays paid, for `authorized_days`
after it was created and for `authorized_clicks` downloads. A download
redirects to a short-lived Active Storage URL; set `disposition` to `"inline"`
to open files in the browser instead of saving them. A refused link shows the
standalone `spree/digitals/unauthorized` page, which offers buyers of paid
orders a button to get fresh links: `POST /digital/:secret/resend` resets the
order's links and e-mails them to the order's address, at most once per link
every ten minutes, and the `spree/digitals/resent` page shows the masked
address. Staff can do the same with the order's "Reset and resend digital
downloads" link. Override both pages to match your store.

### Protected PDFs

Tick "Protected PDF" when uploading a PDF to serve each buyer a personal copy:
a license page after the cover with the order's e-mail and number, then
AES-256 encryption that allows printing and blocks copying and editing. The
copy is built on every download, so nothing is stored per order. It needs the
[qpdf](https://qpdf.sourceforge.io/) command on the server, for example
`apt-get install qpdf`. Prawn renders the license page; its built-in font only
covers Western European characters, so set `license_fonts` for other
languages, or replace `protected_pdf_class`.

## Installation

```ruby
gem 'solidus_digital', github: 'zivotsbedou/solidus_digital'
```

```shell
bin/rails generate solidus_digital:install
```

The generator adds `config/initializers/solidus_digital.rb`, copies the
migrations and runs them. Configure `action_mailer.default_url_options`,
since the e-mail contains absolute download URLs.

### Upgrading from 1.x

- Files move from Paperclip to Active Storage. After migrating, run
  `bin/rails solidus_digital:migrate_paperclip_files` to attach the files under
  `private/digitals`. The Paperclip columns stay until a later release.
  For S3 or another remote Paperclip store, download the original objects before
  upgrading and stage them as `STAGING_DIRECTORY/:digital_id/:attachment_file_name`.
  Run `PAPERCLIP_FILES_ROOT=/absolute/STAGING_DIRECTORY bin/rails solidus_digital:migrate_paperclip_files`.
  Keep the old store available until every attachment is verified. The task exits
  unsuccessfully if any source file is missing; staging the missing files and
  rerunning it skips attachments already migrated.
- The "Digital Delivery" calculator and the digital stock splitter are gone.
  Move shipping methods that use the calculator to a flat rate before
  upgrading.
- Configure the extension with `SolidusDigital.configure`;
  `Spree::DigitalConfiguration` still works but is deprecated.
- The `Spree::Order` helpers and the confirmation e-mail override are gone; the
  links arrive in their own e-mail once the order is paid.

## Shipping

Give digital products their own shipping category and a shipping method, for
example a free flat rate, limited to that category. Solidus then puts digital
items in their own shipment, which the extension ships after the e-mail, and
customers do not pick a carrier for them.

## Configuration

```ruby
# config/initializers/solidus_digital.rb
SolidusDigital.configure do |config|
  config.authorized_days = 30
  config.authorized_clicks = 5
end
```

| Setting | Default | Meaning |
| --- | --- | --- |
| `authorized_clicks` | `3` | Downloads per link; `nil` means unlimited. |
| `authorized_days` | `2` | Days a link works after it was created. |
| `digital_links_count` | `"quantity"` | Links per line item: its quantity or a fixed number. |
| `keep_digitals` | `false` | Keep files when their variant is discarded. |
| `disposition` | `"attachment"` | `"inline"` opens downloads in the browser. |
| `license_fonts` | `{}` | Prawn font family for the license page, e.g. `{normal: "Regular.ttf", bold: "Bold.ttf"}`. |
| `mailer_class` | `"Spree::DigitalMailer"` | Mailer with `download_links_email(order)`. |
| `protected_pdf_class` | `"SolidusDigital::ProtectedPdf"` | Builds protected copies: `new(attachment, line_item).call(output_path)`. |

Override the views under `app/views/spree/digital_mailer/` and
`app/views/spree/digitals/` and the `spree.digitals` and
`spree.digital_mailer` translations to adapt the copy.

## Development

```shell
bin/setup
bin/rake
```

`bin/rake` generates the dummy app in `spec/dummy` on the first run and then
runs the specs. The protected PDF specs need `qpdf`.

## License

MIT © 2011-2015 halo, see [LICENSE](LICENSE.md).

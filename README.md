# solidus_digital

A [Solidus](https://solidus.io/) extension for downloadable products such as
e-books, music and video. This fork targets Solidus 4.8, Ruby 4 and Active
Storage.

## How it works

Attach one or more files to a product's master variant or to any variant in
the admin's "Digital Versions" tab. When a captured payment makes an order
paid, the extension creates download links for each digital line item,
e-mails them with `Spree::DigitalMailer#download_links` and ships the
shipments that hold only digital items, without the stock "shipped" e-mail.
Orders paid later, by bank transfer or a manual capture in the admin, get
their links at that moment. An unpaid order never gets links.

A link works while its order stays paid, for `authorized_days` after it was
created and for `authorized_clicks` downloads. Staff can reset the counters
and send the e-mail again from the order's "Reset and resend digital
downloads" link.

### Protected PDFs

Tick "Protected PDF" when uploading a PDF to serve each buyer a personal copy:
a license page after the cover with the order's e-mail and number, then
AES-256 encryption that allows printing and blocks copying and editing. The
copy is built on every download, so nothing is stored per order. It needs the
[qpdf](https://qpdf.sourceforge.io/) command on the server, for example
`apt-get install qpdf`. Prawn renders the license page; its built-in font only
covers Western European characters, so set `license_font` and
`license_bold_font` to TrueType files for other languages.

## Installation

```ruby
gem 'solidus_digital', github: 'zivotsbedou/solidus_digital'
```

```shell
bin/rails generate solidus_digital:install
```

The generator copies the migrations and runs them. Upgrading from the
Paperclip versions removes the Paperclip columns; upload the files again.

Configure `action_mailer.default_url_options`, since the e-mail contains
absolute download URLs.

## Shipping

Create a shipping method with the "Digital Delivery" calculator, or limit any
shipping method to the shipping category of your digital products, so
customers do not pick a carrier for them. `Spree::Stock::Splitter::DigitalSplitter`
puts digital items in their own package.

## Configuration

`Spree::DigitalConfiguration` holds the preferences:

| Preference | Default | Meaning |
| --- | --- | --- |
| `authorized_clicks` | `3` | Downloads per link; `nil` means unlimited. |
| `authorized_days` | `2` | Days a link works after it was created. |
| `digital_links_count` | `'quantity'` | Links per line item: its quantity or a fixed number. |
| `keep_digitals` | `false` | Keep files when their variant is deleted. |
| `license_font`, `license_bold_font` | `nil` | TrueType fonts for the license page of protected PDFs. |

```ruby
# config/initializers/solidus_digital.rb
Spree::DigitalConfiguration.authorized_days = 30
Spree::DigitalConfiguration.authorized_clicks = 5
```

Override the views under `app/views/spree/digital_mailer/` and
`app/views/spree/digitals/` and the `spree.digitals` and
`spree.digital_mailer` translations to adapt the copy. The download controller
uses `Spree::Config.layout`.

## Development

```shell
bin/setup
bin/rake
```

`bin/rake` generates the dummy app in `spec/dummy` on the first run and then
runs the specs. The protected PDF specs need `qpdf`.

## License

MIT © 2011-2015 halo, see [LICENSE](LICENSE.md).

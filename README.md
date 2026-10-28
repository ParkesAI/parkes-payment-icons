# Parkes payment icons

Payment method SVGs for Rails, with no JavaScript, npm, external image host, or
runtime downloads. Artwork comes from
[Aaron Fagan's SVG Credit Card & Payment Icons](https://github.com/aaronfagan/svg-credit-card-payment-icons).

**Release status:** prepared for release; not yet published to RubyGems.org.
Authorized repository users can install from Git while the repository is internal:

```ruby
gem "parkes-payment-icons", git: "https://github.com/ParkesAI/parkes-payment-icons.git", branch: "master"
```

After the first public release, installation will be:

```ruby
gem "parkes-payment-icons", "~> 0.1"
```

Bundler loads the engine automatically. No generator or initializer is needed
with Propshaft. Explicit `require "parkes/payment_icons"` remains supported.

## Usage

```erb
<%= image_tag "payment_icons/logo/visa.svg", alt: "Visa", width: 40 %>
<%= image_tag "payment_icons/flat-rounded/mastercard.svg", alt: "Mastercard", width: 40 %>
```

Use an empty `alt` when nearby text already identifies the payment method.
The asset path is namespaced under `payment_icons/` to avoid filename collisions.

### Asset pipelines

**Propshaft:** assets are discovered and included in production precompilation
automatically.

**Sprockets 4:** add this to your application's `app/assets/config/manifest.js`
to include the collection in production:

```js
//= link parkes_payment_icons.js
```

Alternatively, link only the individual paths your application uses, such as
`//= link payment_icons/logo/visa.svg`.
Both pipelines support standard `image_tag` and `asset_path` helpers, digested
production URLs, and self-hosted delivery.

## Collection

102 SVGs: 17 names in each of six styles.

| Style | Visa | Mastercard | American Express |
| --- | --- | --- | --- |
| `flat` | ![Visa](app/assets/images/payment_icons/flat/visa.svg) | ![Mastercard](app/assets/images/payment_icons/flat/mastercard.svg) | ![Amex](app/assets/images/payment_icons/flat/amex.svg) |
| `flat-rounded` | ![Visa](app/assets/images/payment_icons/flat-rounded/visa.svg) | ![Mastercard](app/assets/images/payment_icons/flat-rounded/mastercard.svg) | ![Amex](app/assets/images/payment_icons/flat-rounded/amex.svg) |
| `logo` | ![Visa](app/assets/images/payment_icons/logo/visa.svg) | ![Mastercard](app/assets/images/payment_icons/logo/mastercard.svg) | ![Amex](app/assets/images/payment_icons/logo/amex.svg) |
| `logo-border` | ![Visa](app/assets/images/payment_icons/logo-border/visa.svg) | ![Mastercard](app/assets/images/payment_icons/logo-border/mastercard.svg) | ![Amex](app/assets/images/payment_icons/logo-border/amex.svg) |
| `mono` | ![Visa](app/assets/images/payment_icons/mono/visa.svg) | ![Mastercard](app/assets/images/payment_icons/mono/mastercard.svg) | ![Amex](app/assets/images/payment_icons/mono/amex.svg) |
| `mono-outline` | ![Visa](app/assets/images/payment_icons/mono-outline/visa.svg) | ![Mastercard](app/assets/images/payment_icons/mono-outline/mastercard.svg) | ![Amex](app/assets/images/payment_icons/mono-outline/amex.svg) |

Names: `alipay`, `amex`, `code`, `code-front`, `diners`, `discover`, `elo`,
`generic`, `hiper`, `hipercard`, `jcb`, `maestro`, `mastercard`, `mir`, `paypal`,
`unionpay`, and `visa`.

Names follow upstream, not any payment provider's API. Map API values explicitly
in your application and use `generic` for unknown brands. The gem supplies images;
it does not determine which payment methods your business accepts.

## Compatibility

Ruby 3.2 or newer, Rails 7.0 through 8.1, Propshaft 1.x or Sprockets 4.x with
sprockets-rails 3.5.x. The application's Rails version must support its Ruby version.
The gemspec excludes Rails 9 until it is verified.

CI checks the latest patch release in each pair below with both pipelines:

| Ruby | Rails |
| --- | --- |
| 3.2 | 7.0, 7.1, 7.2 |
| 3.3 | 8.0 |
| 3.4 | 8.1 |
| 4.0 | 8.1 |

Each check installs the built gem into a standalone application, exercises
Bundler's automatic require, precompiles in production, and verifies every icon's
digested URL, HTTP status, MIME type, and exact bytes. No database is required.
Older Rails compatibility is not a promise of upstream Rails security support.

## Development and updates

```sh
bin/setup
bundle exec rake test upstream:check
bundle exec rake compatibility
RAILS_VERSION='~> 7.2.0' ASSET_PIPELINE=sprockets bundle exec rake compatibility
bundle exec rake build
```

Use a Ruby version supported by the Rails version being checked. The compatibility
task downloads dependencies into a temporary gem home and removes it afterward.
`pkg/` contains the built gem; no task publishes it automatically.

Upstream updates are explicit and reviewable:

```sh
bundle exec rake 'upstream:update[FULL_40_CHARACTER_COMMIT_SHA]'
bundle exec rake upstream:verify test compatibility
```

The update task fetches the requested commit, copies all six style directories
byte-for-byte, preserves upstream license notices, removes retired icons, and
regenerates [upstream.json](upstream.json). It refuses changed license text and
checks for active SVG content and external references. These checks do not replace
review of new artwork, licensing, or brand usage. Review the diff and update the
collection description and changelog before committing. See
[maintenance and release instructions](docs/RELEASING.md).

`upstream:check` verifies the vendored files offline. `upstream:verify` additionally
fetches the pinned source and compares it with the recorded inventory.

## License and attribution

The Rails wrapper and upstream artwork are distributed under [Apache-2.0](LICENSE).
Artwork is credited to Aaron Fagan and contributors; the wrapper is maintained
independently by Parkes contributors. See [NOTICE](NOTICE).

The pinned upstream revision is `6dd023ae32415ed7b01bf809f15a25613a52098c`.
Its license is preserved in `vendor/upstream/LICENSE`; it has no upstream NOTICE.
Future upstream NOTICE files are included verbatim in `vendor/upstream/NOTICE`.
All original SVG bytes and embedded notices are retained. If upstream files are
ever modified locally, those files must carry prominent modification notices.

Payment brands retain their trademarks. This package does not grant trademark
rights, authorize every use of a logo, or imply endorsement. Follow applicable
brand guidelines. See [CONTRIBUTING.md](CONTRIBUTING.md) for contributions.

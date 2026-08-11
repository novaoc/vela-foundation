# Vela Foundation

Vela's production Rails starter template. New applications are created by
cloning this repository, stamping a product identity, and building on top —
so everything here is meant to hold up in production from day one.

Current foundation (more milestones land incrementally):

- Rails 8.1, PostgreSQL everywhere, propshaft + importmap + Hotwire,
  Solid Queue/Cache/Cable, Tailwind CSS v4, Thruster.
- Production gates baked into the Docker image: a `test` build stage runs
  RuboCop, bundler-audit, importmap audit, Brakeman, and the full test suite
  against a throwaway in-stage PostgreSQL cluster.
- Operational healthcheck at `/healthcheck` (database, migrations, queue
  liveness, storage writability) alongside the standard `/up` boot check.
- Request timeouts (`rack-timeout`, 15s production ceiling) and real client
  IPs behind Cloudflare (`cloudflare-rails`).
- SEO plumbing: `meta-tags` defaults driven from `config/foundation.yml`,
  plus a `sitemap_generator` setup (`bin/rails sitemap:refresh`).
- Accounts (Devise): registration, sign-in, password reset, required email
  confirmation, lockout after repeated failures, 12-character password
  minimum. Cloudflare Turnstile guards registration and password reset when
  `CLOUDFLARE_TURNSTILE_SITE_KEY`/`CLOUDFLARE_TURNSTILE_SECRET_KEY` are set;
  disposable email domains are rejected (`nondisposable`).
- Versioned legal assent: fresh Terms of Service and Privacy Policy pages at
  `/legal/terms` and `/legal/privacy`; signup requires an explicit checkbox
  and stores the accepted versions with timestamp, IP, and user agent.
  The documents are a starting point, **not legal advice** — search them for
  `TODO-OPERATOR` and review with counsel before launch.
- Hosted-preview affordance: when `VELA_HOLODEX_PREVIEW=1` and no
  `SMTP_ADDRESS` is configured, new accounts are confirmed immediately
  (previews cannot send mail); with a relay, normal confirmation applies.
- Organization-scoped subscription billing: configurable Free, Pro, and
  Enterprise tiers with monthly/yearly prices and queryable entitlements;
  Stripe Checkout and customer portal flows; Pay-managed webhook state;
  manual plan overrides that take precedence without hiding management of a
  coexisting subscription.
- Operator-only administration at `/admin/dashboard`: read-only users,
  organizations, memberships, invitations, device sessions, and login events;
  explicit account lock/unlock, validated plan assignment, and session
  revocation actions; Solid Queue visibility at `/admin/jobs`.
- Per-device sign-in tracking records device/browser, IP, last activity, and
  authentication method. The append-only event trail is retained for 12
  months by default and swept daily by Solid Queue.
- Rails-native Material Design 3 system: deterministic light/dark semantic
  tokens generated from the configured brand seed, accessible ERB components,
  local subset Material Symbols Rounded, persisted system/light/dark theme,
  and exact adaptive navigation/layout classes from compact through
  extra-large.
- Production-ready public marketing, authentication, organization, billing,
  and admin shells, with branded static error pages and no runtime asset CDN.
- Optional, default-on digital storefront: guest catalog/cart/checkout,
  server-priced Stripe Checkout, signed receipts, webhook/reconciliation
  fulfillment, preview-only payment simulation, strict inventory reservation,
  Active Storage images, bounded CSV import, and operator-only administration.

## Product identity

`config/foundation.yml` holds the product identity: application name, logo,
brand seed color, default page title/description, social links, support and
legal mailboxes, domain, and feature flags. It is available everywhere as
`Rails.configuration.x.foundation` (string or symbol keys). Edit it first
when turning the template into a real product.

## Material Design 3

The design system is documented in
[`docs/MATERIAL_DESIGN_3.md`](docs/MATERIAL_DESIGN_3.md), including component
usage, accessibility rules, adaptive breakpoints, theme behavior, and brand
re-seeding. Generated color CSS and JSON are committed, so production needs no
Node runtime. To intentionally regenerate after changing
`brand_seed_color`:

```sh
cd tools/material
npm ci
npm run generate:tokens
cd ../..
tools/material/generate_symbols.sh # only when the symbol inventory changes
bin/rails tailwindcss:build
```

Offline template-renaming environments with Node can run
`node tools/material/dist/generate_tokens.mjs` without installing packages;
the committed bundle contains the pinned color algorithm and has a `--check`
mode. `npm test` verifies the reviewed bundle against a fresh pinned build.

Material Color Utilities and the local Material Symbols subset are
Apache-2.0 licensed; exact versions, revisions, hashes, and notices are in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). The application remains
MIT licensed.

## Quickstart

With a local Ruby (see `.ruby-version`) and PostgreSQL:

```sh
bin/setup        # installs gems, prepares databases, starts the dev server
bin/rails test   # run the test suite
bin/ci           # full local gate: style, security audits, tests
```

Without local Ruby, `bin/dx` runs any command inside a containerized dev
loop (repo mounted into a Ruby container with a persistent bundle volume and
a `vf-pg` PostgreSQL container on the `vf-net` Docker network):

```sh
./bin/dx bundle install
./bin/dx bin/rails db:prepare test
./bin/dx bundle exec rubocop
```

The authoritative gate is the Docker `test` stage, which needs nothing but
Docker:

```sh
docker build --target test .
```

## Self-hosting

The production image is the standard Rails multi-stage `Dockerfile`
(Thruster + Puma on port 80). Provide `RAILS_MASTER_KEY` (or
`SECRET_KEY_BASE`), a PostgreSQL server, and your domain in
`config/foundation.yml`; `docker build .` then produces a deployable image
for Kamal or any container host. Asset precompilation needs no secrets
(`SECRET_KEY_BASE_DUMMY=1` is used at build time). Point your monitoring at
`/healthcheck`.

The default runtime needs only one `DATABASE_URL`. Solid Queue, Solid Cache,
and Solid Cable share that primary database, and their tables are installed by
the primary migration stream. A larger deployment may independently provide
`QUEUE_DATABASE_URL`, `CACHE_DATABASE_URL`, or `CABLE_DATABASE_URL`; only the
named adapters with an override move away from primary. Run a separate
`bin/jobs` process by default. Setting `SOLID_QUEUE_IN_PUMA=1` runs the queue
supervisor inside Puma for a single-server deployment; `0` disables it and any
other value refuses to boot.

Set `APP_HOST` to the public bare host or absolute origin used by every emailed
link, controller-generated absolute URL, and Stripe return URL. Paths, queries,
fragments, credentials, and control characters are rejected, and request `Host`
headers are never used as the canonical origin. Links are HTTPS unless the host
is loopback (`localhost`, `*.localhost`, `127.0.0.0/8`, `::1`, `0.0.0.0`);
preview and production require HTTPS outright. In production outside preview,
`APP_HOST` must be the `domain` from `config/foundation.yml` or a subdomain of
it, so an injected value cannot move payment or mail links off your domain.

Without `APP_HOST`, deployed environments use that same `domain`. Local
`bin/rails server` development instead defaults to `http://localhost:3000` so
confirmation and password-reset links stay on your machine; set `APP_HOST` when
you want development to generate a real hostname.

Provider-neutral mail configuration uses `SMTP_ADDRESS`, `SMTP_PORT` (587 by
default), optional paired `SMTP_USERNAME` / `SMTP_PASSWORD`, exact
`SMTP_ENABLE_STARTTLS_AUTO=true|false`, and `MAILER_FROM`. SMTP wins when it is
present. Without SMTP, hosted preview uses the in-memory adapter; otherwise the
application's explicit production provider remains active. `MAILER_FROM` must
be one mailbox, such as `Product <noreply@example.com>`; both From and Reply-To
are forced to that same application identity. Delivery failures are raised in
every mode except the offline in-memory preview.

Outside hosted preview, set `ACTIVE_STORAGE_SERVICE` to a non-disk service
defined in `config/storage.yml`. A production boot stays secret-free for asset
compilation, but `/healthcheck` rejects the local fallback until cloud storage
is configured and writable. See [`docs/HOSTED_RUNTIME.md`](docs/HOSTED_RUNTIME.md)
for the complete environment, preview, health, and deployment contract.

## Billing setup

Plans, presentation prices, Stripe Price IDs, and entitlements live together
in `config/initializers/pricing_plans.rb`. Replace the descriptive local Price
IDs with `STRIPE_PRO_MONTHLY_PRICE_ID`, `STRIPE_PRO_YEARLY_PRICE_ID`,
`STRIPE_ENTERPRISE_MONTHLY_PRICE_ID`, and
`STRIPE_ENTERPRISE_YEARLY_PRICE_ID` in a deployed environment. Configure Pay
with `STRIPE_PUBLIC_KEY`, `STRIPE_PRIVATE_KEY`, and
`STRIPE_SIGNING_SECRET` (or the equivalent Rails credentials), then register
Stripe webhooks at `/pay/webhooks/stripe`. The web process and `bin/jobs`
worker must both be running so Pay can apply webhook updates.

The organization is the Pay customer and plan owner. Manual operator grants
use the pricing_plans console helpers:

```ruby
organization.assign_pricing_plan!(:enterprise)
organization.remove_pricing_plan!
organization.current_pricing_plan_source # :assignment, :subscription, or :default
organization.plan_allows?(:single_sign_on)
```

Revenue and customer metrics are available in the Rails console through
profitable, reading Pay's locally synchronized records without a live Stripe
query:

```ruby
Profitable.mrr.to_readable
Profitable.arr.to_readable
Profitable.ttm_revenue.to_readable
Profitable.churn(in_the_last: 30.days).to_readable
Profitable.active_subscribers.to_readable
```

## Storefront setup

The complete deploy and operations contract is in
[`docs/STOREFRONT.md`](docs/STOREFRONT.md). In short,
`storefront_enabled: true` (the literal YAML boolean) enables catalog, cart,
checkout, receipt, and storefront-admin routes and UI. Every other value
disables those interactive surfaces. The verified settlement webhook remains
mounted after disable so Checkout Sessions created before a flag change cannot
become paid but unfulfillable; drain them before removing Stripe credentials.

Outside preview, configure `STOREFRONT_STRIPE_SECRET_KEY` (or the existing
`STRIPE_PRIVATE_KEY`), a distinct `STOREFRONT_STRIPE_WEBHOOK_SECRET`, and
`STOREFRONT_STRIPE_MODE=live` or `test`. Production defaults to `live` and
rejects test/live prefix mismatches and obvious placeholders. Register the
storefront endpoint `/storefront/stripe/webhook` separately from Pay's
organization-subscription endpoint `/pay/webhooks/stripe`; their signing
secrets and ledgers have different responsibilities. Never put keys in this
repository.

`VELA_HOLODEX_PREVIEW=1` defaults to a conspicuous local simulator with no
Stripe call and no payment fields. An injected preview can opt into real
Stripe test mode only with `STOREFRONT_PREVIEW_PAYMENT_MODE=stripe`, test keys,
and a signing secret. Live Stripe mode is rejected in preview. Offline preview
also stores uploads locally, sends `X-Robots-Tag: noindex` on normal, health,
and error responses, keeps mail in memory, and auto-confirms new accounts.
Supplying `SMTP_ADDRESS` keeps the preview noindex/simulator/storage behavior
but restores ordinary Devise confirmation mail.

This M8 module is intentionally digital-only
(`storefront_fulfillment_mode: digital`): inventory means limited licenses or
capacity. It does not collect a shipping address or claim to calculate tax.
Before selling physical goods, implement address validation, carrier/fulfillment
workflows, tax, regional restrictions, and corresponding legal language.
Review every `TODO-OPERATOR` in Terms and Privacy with qualified counsel; the
included text is a starting point, not legal advice.
Production/live readiness also rejects the template identity and the default
`storefront_commerce_legal_reviewed: false` marker. External product images
are disabled by default; explicitly allow only controlled HTTPS CDN hosts in
`storefront_external_image_hosts`, or use validated uploads.

## Administration

Application administration is separate from organization roles. An
organization owner or admin has no access to `/admin`; only `User#admin?` does.
There is deliberately no form, registration parameter, seed, or public route
that grants this flag. Promote the first trusted operator from the Rails
console:

```ruby
User.find_by!(email: "operator@example.com").update!(admin: true)
```

Admin resources are read-only except for the named actions shown on their
detail pages. Plan changes validate against `PricingPlans.plans` and call the
same `assign_pricing_plan!` / `remove_pricing_plan!` API used by console
operators. Locking uses Devise's lockable API. Session revocation is enforced
server-side on the affected device's next request, including revoke-all for
account-takeover response.

Every mutating request in the admin and jobs controllers writes one structured
JSON event to the Rails log (`foundation.admin.mutation`) with action, actor
ID, request ID/method, subject type/ID, and outcome. It never includes request
parameters, tokens, credential values, or exception messages. Mission Control
hides positional job arguments and filters keyed arguments/raw data through
Rails' sensitive-parameter filter before rendering.

The `sessions` integration creates a signed first-party device identifier at
sign-in and stores device, IP, and login-event data. The default daily
`SessionsSweepJob` bounds event retention to 12 months. Review the Privacy
Policy's session/cookie language and your jurisdiction's requirements before
launch.

## License

MIT — see [LICENSE](LICENSE).

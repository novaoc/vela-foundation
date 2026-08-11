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
- Coming next: admin, a Material Design 3
  design system, and an optional storefront.

## Product identity

`config/foundation.yml` holds the product identity: application name, logo,
brand seed color, default page title/description, social links, support and
legal mailboxes, domain, and feature flags. It is available everywhere as
`Rails.configuration.x.foundation` (string or symbol keys). Edit it first
when turning the template into a real product.

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

## License

MIT — see [LICENSE](LICENSE).

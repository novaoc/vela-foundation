<!-- foundation:identity -->
# Application

A production-ready Rails application.

- Site: https://example.com
- Support: support@example.com
<!-- /foundation:identity -->

The block above is the product identity. `bin/rename` rewrites it, together
with `config/foundation.yml`; everything else in this file documents the
foundation the application is built on.

## What this is

A Rails 8.1 starter template, MIT licensed, with no proprietary dependencies.
New applications are generated from it, stamped with an identity, and then
built on. Every file here is copied into the generated application, so there
is no hidden runtime, no vendor SDK, and nothing to license.

## What the foundation provides

**Accounts and legal assent.** Devise email/password authentication with
required email confirmation, lockout after repeated failures, and a
12-character password minimum. Cloudflare Turnstile guards registration and
password reset when its keys are present; disposable email domains are
rejected. Signup requires an explicit checkbox assent and stores the accepted
Terms and Privacy versions with a timestamp, request IP, and user agent.
Versioned documents live at `/legal/terms` and `/legal/privacy`.

**OAuth with safe linking.** Google and GitHub sign-in with CSRF-protected
request phases. Identities are stored per provider and uid. An OAuth sign-in
whose email matches an existing local account is never auto-merged — the
person is asked to sign in with their existing credentials and link the
provider explicitly from their settings. Unlinking is refused when it would
leave an account with no way to sign in. First-time OAuth users record legal
assent on an interstitial before any account is created.

**Organizations, roles, and invitations.** Every signup creates a personal
organization unless it arrives through an invitation. Users create additional
organizations, switch between them, rename, and delete them. Roles are owner,
admin, and member. Invitations are emailed with signed, expiring tokens and
route a signed-out recipient through signup into the inviting organization.
Ownership transfer, member removal, and leaving are all guarded so an
organization cannot lose its last owner. `Current.organization` is the
session-persisted scope for application code.

**Billing and plans.** Free, Pro, and Enterprise example tiers with monthly
and yearly prices and queryable entitlements, defined in one initializer. A
public pricing page with an interval toggle, Stripe Checkout, a customer
portal link, and webhook-driven subscription state through Pay. The
organization is the billable entity. Operators can assign a plan manually;
manual assignment takes precedence over a subscription, is marked in the UI,
and still exposes billing management when a live subscription coexists.

**Administration.** An operator console at `/admin/dashboard`, gated on
`User#admin?` alone — organization roles grant no access, and no form, seed,
or route sets that flag. Users, organizations, memberships, invitations,
device sessions, login events, products, and orders are browsable; account
lock/unlock, plan assignment, session revocation, and storefront actions are
the named mutations. Every mutation writes a structured audit event to the
Rails log with the actor id. Solid Queue is visible at `/admin/jobs`.

**Material Design 3.** Light and dark semantic tokens generated from one
brand seed color, a typography and shape scale, elevation and state layers,
and Tailwind utilities mapped onto the tokens. Components are ERB partials
plus Stimulus controllers: buttons, cards, text fields, selects, checkboxes
and switches, chips, focus-trapped dialogs, menus, snackbars, top app bar,
and navigation that swaps between bottom bar, rail, and drawer across the
five breakpoints. Icons come only from a locally subset Material Symbols
Rounded font — no icon CDN, no runtime font fetch. Accessibility rules
(48px targets, visible focus, AA contrast, reduced motion, 200% zoom) are
part of the contract. See
[`docs/MATERIAL_DESIGN_3.md`](docs/MATERIAL_DESIGN_3.md).

**Guest-first storefront** (optional, enabled by default). A catalog,
cart, and checkout that require no account: checkout collects and validates
an email, caps quantity, and shows Terms and Privacy links. Amounts are
always computed server-side from product prices. Fulfillment happens only
through the verified Stripe webhook, which checks signature, session, client
reference, amount, and currency idempotently. Receipts are reachable by the
owning user or through a signed 24-hour token. Admin adds product CRUD with
validated image uploads and a bounded CSV import. The module is digital-only
by design. See [`docs/STOREFRONT.md`](docs/STOREFRONT.md).

**Hosted preview runtime.** A deploy-time flag turns the application into a
disposable preview: local disk storage, `X-Robots-Tag: noindex` on every
response, in-memory mail with automatic account confirmation, and a clearly
labeled checkout simulator that moves no money and collects no card data.
Preview requires no Stripe configuration. See
[`docs/HOSTED_RUNTIME.md`](docs/HOSTED_RUNTIME.md).

**Production gates.** The Docker `test` stage runs RuboCop, bundler-audit,
importmap audit, Brakeman, and the full test suite against a throwaway
PostgreSQL cluster inside the image. `/healthcheck` reports database
connectivity, pending migrations, queue liveness, storage writability, mail
mode, and Stripe readiness without contacting Stripe. Request timeouts and
real client IPs behind Cloudflare are configured.

## Quickstart

Run `bin/rename` first — it is the only command a fresh application needs
before it boots:

```sh
bin/rename --name "Acme Shop" \
  --description "Licenses for the Acme toolchain." \
  --domain acme.example \
  --support-email support@acme.example
```

It validates its arguments, stamps `config/foundation.yml` and the identity
block in this README, prints exactly what changed, and lists what an operator
still has to configure. It is safe to run again: the same arguments produce
byte-identical files. `--check` reports the plan without writing. `--module
AcmeShop` additionally renames the Ruby application module in
`config/application.rb`; without that flag the script touches nothing but
configuration and documentation. The web app manifest, page titles, mail
identity, and legal pages read `config/foundation.yml` at runtime, so they
follow automatically.

Then, with a local Ruby (see `.ruby-version`) and PostgreSQL:

```sh
bin/setup        # install gems, prepare databases, start the dev server
bin/rails test   # run the test suite
bin/ci           # full local gate: style, security audits, tests
```

Without a local Ruby, `bin/dx` runs any command in a container with the repo
mounted, a persistent bundle volume, and a `vf-pg` PostgreSQL container on
the `vf-net` Docker network:

```sh
./bin/dx bundle install
./bin/dx bin/rails db:prepare test
./bin/dx bundle exec rubocop
```

The authoritative gate needs nothing but Docker:

```sh
docker build --target test .
```

Seeds are optional. The application boots and serves every page with an empty
database. `bin/rails db:seed` adds a small demo catalog, and only in
development or a hosted preview — it refuses to run in a real deployment.
There is deliberately no seeded administrator: promote the first operator
from the console (see [Administration](#administration)).

## Product identity and branding

`config/foundation.yml` is the single source of product identity:
application name, logo, brand seed color, default page title and
description, Open Graph image, social links, support and legal mailboxes,
domain, and the storefront feature flags. It is available everywhere as
`Rails.configuration.x.foundation` with string or symbol keys.

The web app manifest is served at `/manifest.webmanifest` and built from that
file by `Foundation::WebManifest`, so its name, description, theme color, and
background color follow the configuration instead of being hardcoded. No
service worker is registered: the foundation ships no offline cache, so it
cannot serve a stale authenticated page.

`public/icon.svg` is a placeholder mark generated from `brand_seed_color`
alone — a full-bleed background with a centered ring in whichever of white or
black contrasts better with the seed. It is square and maskable: everything
visible stays inside the guaranteed-safe centered circle. Regenerate it after
changing the seed:

```sh
bin/rails foundation:icon
```

A test fails if the committed icon does not match the configured seed, so the
drift cannot ship silently. To use a real mark, replace `public/icon.svg`
with your own square SVG (keep the artwork inside the centered 80% circle so
Android's mask cannot crop it) and stop running the task. Add a PNG at the
same path only if you also update the manifest entry's `type` and `sizes`.

Changing `brand_seed_color` also requires regenerating the Material Design 3
tokens, which are committed so production needs no Node runtime:

```sh
cd tools/material
npm ci
npm run generate:tokens
cd ../..
tools/material/generate_symbols.sh # only when the symbol inventory changes
bin/rails tailwindcss:build
```

Offline environments with Node can run `node
tools/material/dist/generate_tokens.mjs` without installing packages; the
committed bundle contains the pinned color algorithm and has a `--check`
mode. `npm test` verifies the reviewed bundle against a fresh pinned build.
Material Color Utilities and the local Material Symbols subset are Apache-2.0
licensed; exact versions, revisions, hashes, and notices are in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). The application itself
remains MIT licensed.

## Self-hosting

The production image is the standard Rails multi-stage `Dockerfile` (Thruster
and Puma on port 80). Provide `RAILS_MASTER_KEY` (or `SECRET_KEY_BASE`), a
PostgreSQL server, and your domain in `config/foundation.yml`; `docker build .`
produces a deployable image for Kamal or any container host. Asset
precompilation needs no secrets (`SECRET_KEY_BASE_DUMMY=1` is used at build
time). Point monitoring at `/healthcheck`.

### Environment

| Variable | Required | Purpose |
|---|---|---|
| `RAILS_MASTER_KEY` / `SECRET_KEY_BASE` | yes | Credential decryption and session signing. |
| `DATABASE_URL` | yes | PostgreSQL. The only database the default topology needs. |
| `APP_HOST` | recommended | Public host or absolute origin for every emailed link, absolute URL, and Stripe return URL. |
| `QUEUE_DATABASE_URL` / `CACHE_DATABASE_URL` / `CABLE_DATABASE_URL` | no | Move one Solid adapter off the primary database. |
| `SOLID_QUEUE_IN_PUMA` | no | Exactly `1` runs the queue supervisor inside Puma; `0` or unset uses `bin/jobs`. |
| `ACTIVE_STORAGE_SERVICE` | in production | Name of a non-disk service in `config/storage.yml`. |
| `SMTP_ADDRESS` | for mail | Relay host; its presence selects SMTP delivery. |
| `SMTP_PORT` | no | Defaults to 587. |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | no | Must be supplied together; plain auth is added only then. |
| `SMTP_ENABLE_STARTTLS_AUTO` | no | Exactly `true` or `false`; defaults to `true`. |
| `MAILER_FROM` | recommended | One mailbox, e.g. `Product <noreply@example.com>`. Defaults to `support_email`. |
| `STRIPE_PUBLIC_KEY` / `STRIPE_PRIVATE_KEY` / `STRIPE_SIGNING_SECRET` | for subscriptions | Pay configuration; webhooks post to `/pay/webhooks/stripe`. |
| `STRIPE_PRO_MONTHLY_PRICE_ID` / `STRIPE_PRO_YEARLY_PRICE_ID` | for subscriptions | Price IDs for the Pro tier. |
| `STRIPE_ENTERPRISE_MONTHLY_PRICE_ID` / `STRIPE_ENTERPRISE_YEARLY_PRICE_ID` | for subscriptions | Price IDs for the Enterprise tier. |
| `STOREFRONT_STRIPE_SECRET_KEY` | for the storefront | Falls back to `STRIPE_PRIVATE_KEY`. |
| `STOREFRONT_STRIPE_WEBHOOK_SECRET` | for the storefront | Distinct from the Pay signing secret; endpoint is `/storefront/stripe/webhook`. |
| `STOREFRONT_STRIPE_MODE` | for the storefront | `live` or `test`; production defaults to `live` and rejects prefix mismatches. |
| `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` | for Google sign-in | Omitting the pair hides the button. |
| `GITHUB_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_SECRET` | for GitHub sign-in | Omitting the pair hides the button. |
| `CLOUDFLARE_TURNSTILE_SITE_KEY` / `CLOUDFLARE_TURNSTILE_SECRET_KEY` | recommended | Bot challenge on registration and password reset. |
| `RAILS_LOG_LEVEL`, `WEB_CONCURRENCY`, `RAILS_MAX_THREADS`, `JOB_CONCURRENCY` | no | Standard runtime tuning. |
| `VELA_HOLODEX_PREVIEW` | never set by hand | Injected by the hosting runtime to mark a disposable preview. |

`APP_HOST` accepts a bare host or an absolute origin, and rejects paths,
queries, fragments, credentials, and control characters. Request `Host`
headers are never used as the canonical origin. Links are HTTPS unless the
host is loopback; production and preview require HTTPS. In production outside
preview, `APP_HOST` must equal the `domain` in `config/foundation.yml` or be
a subdomain of it, so an injected value cannot move payment or mail links off
your domain. Without `APP_HOST`, deployed environments use that `domain`;
local `bin/rails server` uses `http://localhost:3000`.

One `DATABASE_URL` is a complete configuration: Solid Queue, Solid Cache, and
Solid Cable share the primary database and their tables are installed by the
primary migration stream. Run `bin/jobs` as a separate process unless you set
`SOLID_QUEUE_IN_PUMA=1`. The full environment, health, storage, and mail
contract is in [`docs/HOSTED_RUNTIME.md`](docs/HOSTED_RUNTIME.md); billing
details are in [`docs/STOREFRONT.md`](docs/STOREFRONT.md) and
`config/initializers/pricing_plans.rb`.

## Hosted preview

`VELA_HOLODEX_PREVIEW=1` is set by the hosting runtime, never by the
application. It marks a daily-wiped, no-egress preview and has fixed
consequences: Active Storage uses local disk, every response carries
`X-Robots-Tag: noindex`, checkout uses the labeled local simulator instead of
Stripe, and — without an SMTP relay — mail stays in memory and new accounts
are confirmed immediately. Supplying `SMTP_ADDRESS` restores ordinary
confirmation mail while keeping the rest of preview behavior. A preview needs
no Stripe keys at all; `STOREFRONT_PREVIEW_PAYMENT_MODE=stripe` is an
explicit opt-in to Stripe test mode, and live mode is refused.

## Generated applications and publication

Applications are generated from this template by a separate service; that
service is not part of this repository and this repository contains no
publishing, deploy, or repository-visibility code.

A generated application's repository is created **private**. It stays private
until an operator explicitly enables publication for it — there is no
automatic or scheduled step that makes a generated application, its source,
or its preview public. Treat a preview URL as unlisted rather than secret:
preview responses carry `X-Robots-Tag: noindex`, which keeps them out of
search results but is not an access control.

Nothing about publication changes the launch requirements below. A private
repository and an unindexed preview do not substitute for the legal review,
Stripe configuration, and storage setup a real deployment needs.

## Legal review checklist

The Terms of Service and Privacy Policy shipped here were written for this
template as a **starting point, not legal advice**. They are not reviewed for
your jurisdiction, your business model, or your data practices. Before
accepting a real signup or a real payment:

- [ ] Search both documents for `TODO-OPERATOR` and replace every marker:
      operator identity, governing law, refund terms, lawful bases, processor
      list, international transfers, and contact mailboxes.
- [ ] Have qualified counsel review the result for your jurisdiction and
      sector, including consumer, distance-selling, and minimum-age rules.
- [ ] Confirm the version identifiers and "last updated" dates are correct;
      assent records store the version a user accepted, so a substantive
      change means a new version.
- [ ] Reconcile the Privacy Policy with what the application actually stores:
      accounts, organizations, orders, uploaded images, device sessions and
      login events (retained 12 months by default), and Stripe's records.
- [ ] Review cookie and analytics language against anything you add; the
      foundation sets only first-party session and device cookies.
- [ ] Confirm the support and legal mailboxes in `config/foundation.yml` are
      monitored, and that they can receive data-subject requests.
- [ ] For the storefront: complete the commerce checklist in
      [`docs/STOREFRONT.md`](docs/STOREFRONT.md) and then set
      `storefront_commerce_legal_reviewed: true`. Production readiness fails
      until you do. The module is digital-only — selling physical goods
      requires address collection, shipping, tax, and matching terms that are
      not implemented here.
- [ ] Verify the Terms and Privacy links still render on signup, checkout,
      the OAuth assent step, and the public footer. Tests assert this; keep
      them.

## Administration

Application administration is separate from organization roles. An
organization owner or admin has no access to `/admin`; only `User#admin?`
does, and there is deliberately no form, registration parameter, seed, or
public route that grants it. Promote the first trusted operator from the
Rails console:

```ruby
User.find_by!(email: "operator@example.com").update!(admin: true)
```

Admin resources are read-only except for the named actions on their detail
pages. Plan changes validate against `PricingPlans.plans` and use the same
`assign_pricing_plan!` / `remove_pricing_plan!` API available in the console:

```ruby
organization.assign_pricing_plan!(:enterprise)
organization.remove_pricing_plan!
organization.current_pricing_plan_source # :assignment, :subscription, or :default
organization.plan_allows?(:single_sign_on)
```

Revenue and customer metrics read Pay's locally synchronized records without
a live Stripe query:

```ruby
Profitable.mrr.to_readable
Profitable.arr.to_readable
Profitable.churn(in_the_last: 30.days).to_readable
```

Locking uses Devise's lockable API, and session revocation is enforced
server-side on the affected device's next request, including revoke-all for
account-takeover response. Every mutating admin request writes one structured
JSON event (`foundation.admin.mutation`) with action, actor id, request id and
method, subject type and id, and outcome — never parameters, tokens, or
credential values.

## License

MIT — see [LICENSE](LICENSE). Third-party notices for the vendored font
subset and color algorithm are in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

# Provenance log

Clean-room build record for the Vela Foundation. Every entry lists what was
produced, by whom, and from which inputs. The reference-similarity gate
(`vela-simguard`) runs on every milestone; violations block the commit.

| Date | Milestone | Implementer | Inputs |
|---|---|---|---|
| 2026-08-10 | Scaffold | `rails new` 8.1.3.1 in Docker (mechanical) | Rails generator only |
| 2026-08-10 | SPEC.md, bin/dx, PROVENANCE.md | Orchestrating session (spec author; behavioral content only) | Vela product requirements, public docs |
| 2026-08-10 | M1 production base + gates | clean-room agent a564079550774869a | SPEC.md M1, public gem docs |
| 2026-08-10 | M2 accounts + legal assent | clean-room agent a8bfa40e5cda88631 | SPEC.md M2/M9, Devise/nondisposable/turnstile public docs |
| 2026-08-10 | simguard null-model additions: devise+nondisposable generator probes + migrated probe schema (documented uncomment transform) | orchestrator | public generators only |
| 2026-08-10 | M3 OAuth + safe account linking | clean-room agent aaa0acf929934e1da | SPEC.md M3, omniauth public docs |
| 2026-08-10 | M4 organizations | clean-room agent adf1499bf5209da6a | SPEC.md M4, organizations gem public docs |
| 2026-08-10 | simguard null-model addition: organizations generator probe + migrated schema | orchestrator | public generators only |
| 2026-08-10 | M5 billing and plans | clean-room task `/root/m5_billing_cleanroom` | SPEC.md M5; public Pay, pricing_plans, profitable, and Stripe Ruby READMEs/docs/licenses; generated Pay/pricing_plans migrations |
| 2026-08-10 | simguard null-model addition: Pay + pricing_plans generator probe and PostgreSQL schema | clean-room task `/root/m5_billing_cleanroom` | fresh Rails 8.1.3.1 app; public Pay 11.7.0 and pricing_plans 0.4.0 generators only |
| 2026-08-10 | M6 application admin, device sessions, and queue operations | clean-room task `/root/m6_admin_cleanroom` | SPEC.md M6; public madmin 2.4.0, sessions 0.2.2, mission_control-jobs 1.1.0, Devise, Rails, and pricing_plans documentation/licenses |
| 2026-08-10 | sessions install migrations/model/job/initializer | public `sessions:install` generator (mechanical), invoked by `/root/m6_admin_cleanroom` | fresh public sessions 0.2.2 generator output only |
| 2026-08-10 | simguard null-model additions: sessions generator probe and combined public-generator PostgreSQL schema | clean-room task `/root/m6_admin_cleanroom` | fresh Rails 8.1.3.1 app; public Devise 5.0.4, organizations 0.5.0, Pay 11.7.0, pricing_plans 0.4.0, and sessions 0.2.2 generators only |
| 2026-08-10 | M7 Material Design 3 tokens, components, adaptive shells, and local icon subset | clean-room task `/root/m7_material_cleanroom` | SPEC.md M7; public Google Material Design 3 documentation; public `@material/material-color-utilities` 0.4.0 and `google/material-design-icons` revision `50f0603134ce7b70b2d71b686cc13e8b57ccb74c`; public Rails, Tailwind CSS, Stimulus, and fontTools documentation |
| 2026-08-11 | M8 guest-first digital storefront, verified Stripe settlement, inventory reservations, receipts, imports, and administration | clean-room task `/root/m8_storefront_cleanroom` | SPEC.md M8; public Rails 8.1 Active Record/Active Storage/MessageVerifier docs; public Stripe Checkout/webhook and stripe-ruby docs; Ruby CSV docs; PostgreSQL row-locking docs; local M7 MD3 system |
| 2026-08-11 | M9 completion: canonical-domain pinning for production APP_HOST, host-based link scheme policy, local development origin fallback, controller URL host parity, and queued-mail delivery contract | clean-room task `m9_runtime_completion` | SPEC.md M9 and Global conventions; this repository; public Rails 8.1 Action Controller/Action Mailer/Active Job routing and URL documentation; public Ruby `URI` and `IPAddr` documentation |
| 2026-08-11 | M9 hosted preview, immutable runtime configuration, provider-neutral mail, canonical origins, and single-database production adapters | clean-room task `/root/m9_runtime_cleanroom` | SPEC.md M9; public Rails 8.1 configuration, Action Mailer, Active Storage, Active Record multiple-database, Action Cable, Rack middleware, Puma, Devise, Mail, Solid Queue 1.6, Solid Cache 1.0, Solid Cable 4.0, URI, and PostgreSQL documentation/current dependency source; public generator schemas already present in the clean repository |

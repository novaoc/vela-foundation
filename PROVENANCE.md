# Provenance log

Clean-room build record for the Vela Foundation. Every entry lists what was
produced, by whom, and from which inputs. The reference-similarity gate
(`vela-simguard`) runs on every milestone; violations block the commit.

| Date | Milestone | Implementer | Inputs |
|---|---|---|---|
| 2026-08-10 | Scaffold | `rails new` 8.1.3.1 in Docker (mechanical) | Rails generator only |
| 2026-08-10 | SPEC.md, bin/dx, PROVENANCE.md | Orchestrating session (spec author; behavioral content only) | Vela product requirements, public docs |
| 2026-08-10 | M1 production base + gates | clean-room agent a564079550774869a | SPEC.md M1, public gem docs |

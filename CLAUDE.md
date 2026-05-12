# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project

`brain` is a Ruby on Rails monolith. `brain.md` is the **canonical design doc** — read it before doing anything substantive. Concrete work is broken down into milestone files under `pm/`.

## Stack (pinned)

The DHH "majestic monolith / no-build / one-person framework" stack, latest stable as of 2026:

- **Ruby 4.0.x**, **Rails 8.1.x** — no exceptions, no version drift.
- **SQLite** for development *and* production. (DHH/37signals validated; Solid adapters make this real.)
- **Solid Trifecta**: Solid Queue (jobs), Solid Cache (cache), Solid Cable (websockets) — all DB-backed. No Redis.
- **Asset pipeline**: Propshaft. **JS**: importmap-rails (no bundling, no transpilation). **CSS**: Tailwind via `tailwindcss-rails` (standalone binary — still no Node). **NO Node, NO esbuild, NO Webpack, NO npm.**
- **Frontend interactivity**: Hotwire — Turbo + Stimulus. Server-rendered ERB. No SPA, no React, no Vue.
- **Auth**: Rails 8 built-in `bin/rails generate authentication`. No Devise.
- **Background jobs**: Active Job → Solid Queue. Use Rails 8.1 **Active Job Continuations** for any job >30s.
- **Deployment**: Kamal 2 to a single Linux box (or small fleet). Thruster in front for HTTP/2 + asset caching. Encrypted Rails credentials → Kamal secrets.
- **CI**: Rails 8.1 `bin/ci` driven by `config/ci.rb`. Local-first; GitHub Actions only mirrors what `bin/ci` runs.
- **Testing**: **Minitest + fixtures.** No RSpec. No FactoryBot. No Faker. No VCR. Use Rails' built-in `ActiveSupport::TestCase`, `ActionDispatch::IntegrationTest`, `ActiveSupport::TestCase.parallelize`, and system tests via Capybara + Selenium (Rails defaults).

### Third-party libraries

**Default to no.** Rails + the listed defaults cover ~95% of needs. Before adding any gem outside the generated `Gemfile`:

1. State what Rails primitive you considered and why it falls short.
2. Ask the user. Wait for explicit approval.

Exceptions (no need to ask): security patches, drop-in replacements for an existing gem with a deprecation, gems Rails itself pulls in.

---

## Workflow

1. **Design doc first.** Anything non-trivial gets reflected in `brain.md` before code. If `brain.md` doesn't cover it, stop and update `brain.md` first.
2. **Break work down into `pm/NNNN-short-slug.md` milestone files.** Each milestone has: goal, verifiable success criteria, ordered steps, status. See `pm/README.md`.
3. **Commit intermittently — especially when happy.** After each milestone step verifies green (tests pass, feature works), commit. Small, reversible commits over big ones. Conventional-ish messages (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
4. **Run `bin/ci` before any commit that touches code.** If `bin/ci` is red, do not commit.
5. **Test everything.** Every model, controller, job, and mailer gets a test. Use fixtures (`test/fixtures/*.yml`) for data — not factories. Integration tests for flows, system tests for the few critical user journeys.

---

## Behavioral guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Rails-specific conventions

- **Skinny controllers, rich models.** Business logic in models (or `app/models/concerns/`), not service objects unless the user asks. Rails' "fat model, skinny controller" stands.
- **No service-object / interactor / form-object / query-object gems.** If you reach for one, you're probably overcomplicating — re-read §2.
- **Strong Parameters** in every controller. No `params.permit!`.
- **DB-first.** Constraints, foreign keys, indexes, NOT NULL — define in migrations. Validations in models are belt-AND-suspenders, not a substitute.
- **Migrations are forward-only in spirit.** Write reversible migrations, but assume rollback only works in dev.
- **Fixtures over factories.** Reference them by name (`users(:alice)`). Keep fixture data minimal and shared.
- **No `Time.now`** — use `Time.current`. No `Date.today` — use `Date.current`.
- **i18n from day one** even if only `en` exists. No hardcoded user-facing strings in templates.
- **Turbo Frames + Streams** before reaching for Stimulus. Stimulus before reaching for custom JS. Custom JS as a last resort.

## Commands

The Rails app does not exist yet. Once `pm/0001-bootstrap-rails-app.md` is complete:

- `bin/setup` — install deps, prep DB
- `bin/dev` — run development server (Foreman-style)
- `bin/rails test` — run all tests
- `bin/rails test test/models/foo_test.rb` — single file
- `bin/rails test test/models/foo_test.rb:42` — single test at line
- `bin/rails test:system` — system tests (Capybara + Selenium)
- `bin/ci` — full local CI (lint + tests + security audit, per Rails 8.1)
- `bin/kamal deploy` — deploy to production

# 0006 — Timeline home

## Goal

The signed-in home is a quiet timeline of everything that happened — receipts captured, documents received, invoices issued, bank transactions posted — grouped by day, sorted newest-first. No dashboard, no metrics, no calls to action. Reading it should feel like opening a journal, not a to-do list.

## Why now

Right after the shell. The web app currently sends signed-in users to `/receipts/new` — a stressful "do something" surface. brain.md is explicit that the system should "feel like a habit, not a tool" and surface "only when something needs a human decision". A timeline of past activity is the right home: confirms the system is working, costs zero attention, takes you to action only if you choose.

This milestone also validates the recordables pattern in production: `Filing` and `BankTransaction` merge into one stream with no joins, no STI gymnastics.

## UX language

Same vocabulary as the rest of the app:
- **Quiet** — muted palette, no badges shouting at you, no charts.
- **Scannable** — three columns: time, what, amount. Day labels (Today / Yesterday / "May 8") set context.
- **Honest** — shows what's *there*, not what you're missing. Status pills are subtle.
- **No demands** — links to detail are optional. The empty state nudges to capture; the populated state stays out of the way.

```
ACTIVITY

TODAY
─────────────────────────────────────────────────────────
14:10  Parking Madrid Centro            -€4.50    captured
13:32  Le Pain Quotidien brussels      -€23.50    bank charge

YESTERDAY
─────────────────────────────────────────────────────────
21:32  Le Pain Quotidien               -€23.50    captured
08:15  Ryanair invoice                              received

MAY 8
─────────────────────────────────────────────────────────
06:00  Santander statement                          received
```

## Success criteria

- [x] New `Timeline` PORO in `app/models/timeline.rb` that merges `Filing` and `BankTransaction` into a single sorted event list, with helpers `events`, `events_by_day`, `empty?`.
- [x] `TimelinesController#show` at `/timeline`, layout `"app"`, auth-gated.
- [x] Brand link in `app.html.erb` points to `/timeline` (not `/`).
- [x] `PagesController#home` redirect updated: signed-in users go to `/timeline` (not `/receipts/new`).
- [x] Timeline view renders day-grouped entries with: time chip, title, secondary line, signed amount, subtle status pill.
- [x] Empty state: short message + a "Capture a receipt" link.
- [x] All existing tests still green; new tests cover: Timeline model merges + sorts + filters trashed, controller auth gate, controller renders day groups, controller empty state.
- [x] `bin/ci` green.

## Steps

1. Build `Timeline` PORO + model test. → verify: `bin/rails test test/models/timeline_test.rb`.
2. Add `resource :timeline, only: :show` route, generate `TimelinesController`. → verify: `bin/rails routes | grep timeline`.
3. Build show view + per-event partials (`_filing_entry`, `_bank_transaction_entry`) + `TimelineHelper#timeline_day_label`, `#timeline_amount`. → verify: visual / integration test.
4. Add CSS for `.timeline`, `.timeline__day`, `.timeline__entry`, `.entry__time/body/right/amount/pill`. → verify: visual.
5. Update `app.html.erb`: brand → `timeline_path`. Don't add a "Home" nav tab — brand serves that role.
6. Update `PagesController#home` redirect: → `timeline_path`.
7. Update existing `navigation_test` for the new redirect target.
8. Integration tests for `/timeline`. → verify: green.
9. `bin/ci` → exit 0.
10. Commit.

## Notes

- Timeline limit: 100 most recent events for v1. Pagination ("Load more") if/when N grows.
- No filter UI yet (by kind, by status). Date-based grouping is enough until Luis asks for filtering.
- The PORO lives in `app/models/` because it's a domain concept; we don't have an `app/services/` and we won't introduce one (CLAUDE.md §third-party / §abstractions).
- `BankTransaction` has `posted_on :date` (no time). Timeline treats it as end-of-day for sort purposes so day grouping is clean.
- Status pill copy uses the underlying enum verbs: `filed`, `pending`, `needs_review`, `matched`, `unmatched`, `draft`, `sent`, `paid`. Tone: lowercase, neutral.
- **Result:** 64 tests, 263 assertions, 0 failures. bin/ci green.
- BankTransaction has no time-of-day; timeline sorts those at the *end* of their date so they appear below same-day filings.

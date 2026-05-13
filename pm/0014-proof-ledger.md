# 0014 — proof ledger

## Goal

Replace the user-facing fan-out of folder × filing-status × invoice-status ×
bank-matched with a single mental model: **every money-move is one event
with two sides — money (bank line) and proof (receipt/invoice/document) —
and a user-visible state of Proven / Open / Dismissed.** Build the matching
UI that bridges the two sides when the bank starts syncing.

## Why

User feedback (2026-05-13): *"capture? capture what? I don't know what any
of the statuses mean, I don't know what statuses are possible, I don't know
what still needs work and what doesn't. when bank expenses start coming in
how would I link a receipt to them? have you thought about a data model
around expenses and income and lots of 'proof' around it?"*

The model is correct underneath (`Filing` + `BankTransaction.matched_filing_id`).
What's missing is the *concept* on top — and the names + state labels +
match UI that make that concept usable.

## Success criteria

- [ ] **Concept introduced**: a `Ledger::Entry` view-model that exposes
      `kind` (income / expense / transfer / tax / corporate / unknown),
      `state` (proven / open / dismissed), `money_side` (BankTransaction or
      nil), `proof_side` (Filing or nil), `at` (date), `amount` (signed €).
- [ ] **State derivation rules** documented and tested:
  - **proven** — both sides present, amounts within ±0.01€, dates within
                 ±7 days.
  - **open**   — exactly one side present, OR both present with mismatch
                 (amount diverges or dates too far apart).
  - **dismissed** — explicitly marked (new column or scope).
- [ ] **Plain-English status labels** replace lowercased enum values
      everywhere user-visible. Helper `ledger_state_label(entry)` returns
      e.g. "Waiting on you", "Filed", "Sent — awaiting payment", "Dismissed".
- [ ] **Bottom nav rename**: Home / + Receipt / Invoices. ("Capture" is
      gone as a top-level surface; promoted to a header `+ Receipt`
      button and a hero affordance on empty Home.)
- [ ] **Tray surfaces "Open" entries**: each tray row says what to do in
      one verb — "Match a receipt" (unmatched bank txn), "Send to Lab900"
      (draft invoice), "File this" (needs-review inbound doc),
      "Snap a photo" (filing exists without a Receipt yet — rare edge).
- [ ] **Match UI**: tap an unmatched bank-tx tray row → see candidate
      receipts within ±€5 and ±7 days, ranked by closest. Tap one →
      match → row disappears, stream prepends the proven entry.
- [ ] **"Dismiss"** option on every tray row, with confirmation. Sets
      `dismissed_at` on the right model (Filing.trashed_at or a new
      column on BankTransaction).
- [ ] **Home counts**: the tray pill shows the actual count of Open
      items; when 0, says "All clear." (already does — verify the count
      now reflects the new Open semantics).
- [ ] `bin/ci` green; system test exercises the match flow.

## Steps

1. **Bump roadmap** so 0014 is proof-ledger, 0015 is ledger-visual, 0016+
   shift forward. → verify: `ls pm/`. (Done.)
2. **`Ledger::Entry` PORO** at `app/models/ledger/entry.rb`. Constructor
   takes a Filing and/or a BankTransaction. Exposes the fields above.
   → verify: model test for each derivation rule.
3. **Status taxonomy + helper** at `app/helpers/ledger_helper.rb`:
   `ledger_state_label(entry)`, `ledger_state_verb(entry)` — the latter
   returns the one-word user action for Open entries.
   → verify: helper test for every combination.
4. **`BankTransaction.dismissed_at`** column + scope. (Filing already
   has `trashed_at` — keep that semantics.) → verify: migration.
5. **Home model rewrite** to compose `Ledger::Entry` rows instead of
   raw Filings/BankTransactions. Stream = proven entries; tray = open
   entries. The tray contents and order are derived from the new state.
   → verify: model + controller tests.
6. **Tray rows reshaped** so each shows the right action verb. Inbound
   docs still get folder pills; invoices still get Send/Edit; unmatched
   bank txns get a new "Match" affordance.
   → verify: integration test.
7. **Match UI** — new controller `Ledger::MatchesController#new` (the
   candidates list) + `#create` (the match itself). View renders a small
   list of candidate receipts ranked by `(amount_diff, date_diff)`.
   Tap a candidate → POST → `BankTransaction.update(matched_filing_id: …)`.
   → verify: controller test, system test of the full flow.
8. **Nav renames**: drop the "Capture" link from the bottom-nav and the
   header. Add a `+ Receipt` button in the header (and on empty Home).
   Add `+ Invoice` if relevant on Invoices index. → verify: integration
   test for the new nav.
9. **Status label sweep**: replace every lowercased enum-string render
   with `ledger_state_label`. Tray rows, stream entries, invoice
   document. → verify: integration test asserts no raw `pending` /
   `needs_review` / `draft` strings in user-facing HTML.
10. **`bin/ci` + commit.** Per-step commits if helpful. → verify: green.

## Status

🟡 next

## Notes

- Don't drop the underlying enums (`Filing.status`, `IssuedInvoice.invoice_
  status`, etc.) — they capture real lifecycle. `Ledger::Entry` derives a
  *user-visible* state on top, leaving the technical states intact.
- "Match" auto-tolerance numbers (±€5, ±7 days) are heuristics for v1;
  surface the candidates by closeness but don't auto-match — the user
  always confirms.
- This milestone is a prerequisite for the design system implementation
  (0015 — ledger-visual) because the components it produces (tray row
  verb, status pill, match-candidate list) are what gets styled.
- Bank transaction *import* (real Holded sync) is its own milestone
  (0019 — holded-adapter). v1 of this milestone works with whatever
  bank txns exist via fixture/manual entry.

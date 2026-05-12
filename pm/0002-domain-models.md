# 0002 — Domain models

## Goal

The core nouns from `brain.md` exist as ActiveRecord models with DB constraints, fixtures, and unit tests. No UI yet, no external integrations yet.

## Success criteria

- [ ] Models exist with migrations, indexes, foreign keys, NOT NULLs:
  - `User` (already from auth generator)
  - `Setting` — singleton-ish key/value for Holded API creds, gestoría email, etc.
  - `IncomingDocument` — anything received (email, capture, sync). Has `kind` enum (expense_receipt, bank_statement, tax_doc, corporate, unknown), `source` enum (capture, email, holded_sync, manual), `received_at`, `original_blob` (Active Storage), `certified_blob`, `holded_ref`, `status` enum (pending, filed, needs_review).
  - `Expense` — semantic record for an outgoing payment. Belongs_to `incoming_document` (optional). Fields: `paid_on`, `amount_cents`, `currency`, `vendor`, `country`, `note`, `bank_transaction_id` (optional).
  - `IssuedInvoice` — `period_year`, `period_month`, `client_name`, `number`, `issued_on`, `amount_cents`, `status` enum (draft, approved, sent, paid), `holded_ref`, `verifactu_ref`, `pdf_blob`.
  - `BankTransaction` — synced from Holded. `posted_on`, `amount_cents`, `description`, `holded_ref` (unique), `matched_expense_id` (optional).
  - `ReviewItem` — `reason` enum (unmatched_transaction, unrecognized_document, …), `subject_type`+`subject_id` (polymorphic), `resolved_at`.
- [ ] Fixtures for each model in `test/fixtures/`. Realistic-but-minimal data.
- [ ] Unit tests cover: validations, enum behavior, key associations, one happy-path scope per model.
- [ ] `bin/ci` green.

## Steps

To be detailed at start of milestone (don't over-spec ahead of time).

## Notes

- Money: store as `amount_cents :integer`. No Money gem yet — Ruby integers + helper methods cover this until proven insufficient.
- Holded refs are stored as plain strings, not enforced foreign references (Holded is the source of truth there).

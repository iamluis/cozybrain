# 0012 — real invoice fields (clients, tax, period, money in €)

## Goal

Make an invoice carry every field a Spanish SLU actually needs to send a
legal document to a B2B client, modelled as data rather than text. Money is
displayed and edited in euros throughout. The Holded adapter will later
consume this structured payload and apply VeriFactu/QR/AEAT — that piece
stays out of scope.

## Why

User feedback (2026-05-13): asked for a UX study on invoice fields. After
a four-fork conversation we picked:

- a real **Clients** table (Lab900 as row 1)
- **tax treatment** as a per-client default with per-invoice override
- **service period** as an explicit start→end date range
- **payment terms + IBAN footer** and a **notes** field on every invoice
- money input and display in **euros with 2 decimals**

Today the invoice has `client_name` as a string, no VAT/address modelled,
no IVA, no service period, and money is shown in cents. Useless to
actually send.

## Success criteria

- [ ] `clients` table exists with: `legal_name`, `vat_number`, `address`, `country`, `contact_email`, `default_iban`, `default_tax_treatment`, `default_payment_terms_days`, `notes`.
- [ ] Lab900 is seeded (country `BE`, tax `intra_eu_reverse_charge`, terms 30 days; the rest blank — user fills via the form).
- [ ] `IssuedInvoice.belongs_to :client`. Existing fixture/test data migrated.
- [ ] Invoice schema gains: `tax_treatment`, `service_period_start`, `service_period_end`, `payment_terms_days` (nullable, falls back to client default), `iban_override` (nullable), `notes` (text, nullable).
- [ ] `IssuedInvoice` exposes virtual euro accessors: `subtotal`, `tax_amount`, `total` (all `BigDecimal`). Line item exposes `unit_amount` (`BigDecimal`). All inputs in the form are euros with `step="0.01"`.
- [ ] Subtotal / tax / total computed from line items + treatment:
  - `intra_eu_reverse_charge`: subtotal = total, no Spanish VAT, footer mentions Art. 196.
  - `domestic_vat_21`: subtotal + 21% = total, VAT row shown.
  - `exempt`: subtotal = total, exemption footer.
- [ ] Invoice form (when draft):
  - Client picker (single option today: Lab900) at top.
  - Service period start + end (defaults: month start / month end).
  - Tax treatment select, pre-filled from client default.
  - Payment terms (number input, days), with placeholder showing client default.
  - IBAN override (text, optional, placeholder = client default).
  - Notes textarea at the bottom.
- [ ] Invoice document view (sent + draft) renders: client legal name + VAT + address; service period sentence ("Services rendered DD MMM – DD MMM YYYY"); subtotal / tax / total rows; legal mention for the tax treatment; payment terms + IBAN footer; notes if any.
- [ ] Filing's period_year/month derived from `service_period_end` so the gestoría folder still lands correctly.
- [ ] `bin/ci` green.

## Steps

1. **Bump milestones** (0013 folder-sync, 0014 weekly-pulse, 0015 holded-adapter, 0016 deployment-kamal). → verify: `ls pm/` shows no gaps.
2. **Migration 1**: create `clients` table with all columns above. Add `Client` model. Validate `legal_name` presence. → verify: model test.
3. **Seed Lab900**: `db/seeds.rb` upserts Lab900 with the agreed-on placeholder values. → verify: `rails db:seed` is idempotent.
4. **Migration 2**: add `client_id` (nullable initially), `tax_treatment`, `service_period_start`, `service_period_end`, `payment_terms_days`, `iban_override`, `notes` to `issued_invoices`. → verify: schema dump matches.
5. **Backfill**: a small data migration sets `client_id` for the Lab900-named invoices in fixtures + dev DB, and copies `period_year/month` → `service_period_start/end`. → verify: `rails db:migrate` produces valid rows.
6. **Make `client_id` non-null** and drop the redundant `client_name` column (kept only as a backwards-compat accessor that reads `client.legal_name`). → verify: schema.
7. **`IssuedInvoice` model**: add `belongs_to :client`, `TAX_TREATMENTS` constant, validation. Add virtual euro accessors (`unit_amount`, `subtotal`, `tax_amount`, `total`). Refactor `recompute_total!` to use the treatment. → verify: model tests for each treatment + line-item math.
8. **Line item**: add virtual `unit_amount` BigDecimal accessor, mirror of `Receipt#amount`. → verify: model test.
9. **`Invoice.draft_next`**: take `client:` (not template's `client_name`), pull defaults from it, set `service_period_start/end` to start/end of next month, copy template line items but re-express prices in euros. → verify: controller test.
10. **Form rewrite** (`invoices/show.html.erb` + `_lines_editable.html.erb`): client picker, service period inputs, tax-treatment select, payment terms, IBAN, notes. Line item `unit_amount` field replaces the `unit_amount_cents` field; "cents" hint gone. Live total Stimulus reads from euros. → verify: by eye + system test of the auto-save flow.
11. **Document view**: render the new fields on both draft (read-with-edit) and sent (read-only) layouts. Legal mentions per treatment via helper. → verify: integration test asserts the right footer text per treatment.
12. **Filing period derivation**: invoice `after_save` hook sets `filing.period_year = service_period_end.year`, `filing.period_month = service_period_end.month`. → verify: model test.
13. **Update fixtures** to reflect the new schema. → verify: tests green.
14. **bin/ci + commit.** → verify: green, then `feat(invoice-real-fields): clients, tax treatments, service period, € everywhere`.

## Status

🟢 done

## Notes

- Snapshotting client identity onto sent invoices (so a later address change
  doesn't rewrite history) is a follow-on. For v1: send-time the data is
  what the PDF carries; if Lab900 changes their address, drafts re-read but
  sent ones display the snapshot via a `frozen_recipient` JSON column.
  Defer to a separate milestone unless it bites.
- Real fix for the cents/euros split is to keep `_cents` integer columns and
  expose decimal accessors — same pattern Receipt already uses. No
  precision loss, no float math.
- A Clients *index/edit* surface is out of scope here. For now the user
  edits Lab900's fields via a single-record edit page hidden under
  `/settings/client` or by editing the seed and re-running. We'll grow a
  real Clients UI when the second client appears.
- Tax treatments are an enum string column, not a separate join table. Three
  values today; each adds three lines of code if a fourth appears.
- Currency is still always EUR. Multi-currency is far out.

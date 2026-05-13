# 0011 — edit everything, inline

## Goal

Anything you can create, you can fix. Anything you can fix, you can fix on
the page you're already looking at. Receipts gain a real edit surface;
invoices stop demanding a "Save changes" tap. Both happen inline, not on a
separate `/edit` page.

## Why

User feedback (2026-05-13): *"I can't edit receipts if something goes
wrong, editing an invoice is still hard."* The previous milestone (0010)
made the home calm; this one fixes the friction the user actually hits when
they put a finger on something.

## Success criteria

- [ ] **Receipts**:
  - [ ] `ReceiptsController#edit` and `#update` exist.
  - [ ] Fields: vendor, amount, paid_on, country, note (the filing note).
  - [ ] Edit form opens *inline on the receipt's show page* — no separate `/edit` URL change (rendered via Turbo Frame swap).
  - [ ] Validation errors render inline; the page does not reload.
  - [ ] Stream entries on `/home` link to the receipt; the receipt page has an "Edit" affordance that swaps the read-only card for the form.
- [ ] **Invoices**:
  - [ ] Header fields (client name, period month) are editable in the same `form_with`.
  - [ ] Running total recomputes client-side as quantity / unit_amount changes (Stimulus, no server round-trip).
  - [ ] On blur of any form field, the form auto-submits (debounced ~500ms) — no explicit "Save changes" tap needed.
  - [ ] Removing a line item via the existing "✕" works without an explicit save (the auto-save covers it).
  - [ ] An explicit "Save changes" button stays as a fallback for users who Tab+Enter their way through.
- [ ] `bin/ci` green.

## Steps

1. **Bump roadmap (0012 folder-sync, 0013 weekly-pulse, 0014 holded-adapter, 0015 deployment-kamal).** → verify: `ls pm/` shows no gaps.
2. **`ReceiptsController#edit` + `#update`**: strong params, redirect to `receipt_path(@receipt)` on success, render `:edit` on failure. → verify: controller test for happy path + validation failure.
3. **Receipt `_form` partial** wrapped in a `<turbo-frame id="receipt_<id>">`. The show page renders the read-only card inside the same frame ID by default; clicking "Edit" swaps the frame content to the form (via Turbo Frame navigation). → verify: tapping Edit shows the form in place; submitting redirects back to the same frame showing the card.
4. **Filing note**: `Filing` has a `note` column already (used by capture). Receipt edit form persists `receipt.filing.note` via `accepts_nested_attributes_for :filing` on `Receipt` (or a virtual setter). → verify: editing the note updates `receipt.filing.note`.
5. **Invoice header editing**: add `client_name` and `period_month` (+ `period_year` as hidden) to the existing `form_with` in `invoices/show.html.erb`. Use `text_field` for client name and a `select` for the month. → verify: changing the client name + saving updates the invoice; period change updates the filing too.
6. **Stimulus: live total**: extend `invoice_lines_controller.js` to read all quantity × unit_amount inputs on `input` events and update a `<span data-invoice-lines-target="total">`. Render the span in the invoice template just above the actions. → verify: typing in a quantity field changes the displayed total instantly with no save.
7. **Stimulus: auto-save**: add a debounced `submit` action wired to `input change` and `change` events on every form field within the invoice form. 500ms debounce. Use `requestSubmit()` so Rails' Turbo handles it as a Turbo Form submit. → verify: editing a quantity, waiting ~600ms, then refreshing shows the change persisted.
8. **Save indicator**: tiny non-noisy "Saved · 12:04" pill that updates on successful save (driven by a Turbo Stream from `update` or a Stimulus listener on `turbo:submit-end`). → verify: pill appears after auto-save.
9. **Tests**: receipt controller test (edit/update happy + sad path), invoice update test for header edit, system test that exercises auto-save (defer if Capybara setup is a yak-shave). → verify: `bin/rails test` green.
10. **bin/ci + commit.** → verify: green; commit message `feat(edit-everything): receipts editable, invoices auto-save with live total`.

## Status

🟢 done

## Notes

- Auto-save bias: when in doubt, save. Debounce keeps it from being chatty.
  If two concurrent saves race, Rails' last-write-wins is fine for a
  single-user app.
- Period editing on invoices touches `filing.period_year` /
  `filing.period_month` too — the filing belongs_to the same period.
- "Edit" on a *sent* invoice is intentionally not allowed (`refuse_unless_draft`
  already enforces this). Same rule applies to receipts that have been
  matched to a bank transaction? — defer; v1 lets you edit any receipt.
- Keep the explicit Save button. Auto-save can fail silently if the user is
  offline; a visible button is a safety net.
- No new gems. Stimulus + Turbo only.

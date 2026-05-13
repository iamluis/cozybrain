# 0013 — stabilize UI

## Goal

Make the UI we shipped in 0010–0012 actually feel solid. Fix the bugs that
are visible right now. Cover the golden paths with system tests so future
churn doesn't regress them. Tighten polish on what was rushed. Hand back a
short browser-eyes punch list for things only the user can verify.

## Why

User feedback (2026-05-13): *"our road map should be stabilize ui, 14, 16,
13, 15"* — promoting stabilization above all remaining features. Then sent
a screenshot of the current invoice draft surface that immediately exposed:
stale client snapshot leaking into the Send button, no totals breakdown on
drafts, Lab900 has no VAT/address/IBAN visible because dev seed never set
them, and a "settings panel" feel at the bottom of the document.

## Success criteria

- [ ] **Bugs (provable, code-level):**
  - [ ] Draft invoices show the live client name everywhere, not the
        snapshot. (Send button no longer says "Lab900 BBVA" or similar.)
  - [ ] Drafts render the subtotal / IVA / total breakdown so flipping
        the tax treatment shows its effect.
  - [ ] Blank tax_treatment override doesn't fail validation
        (`allow_blank: true` or `before_validation` normalize).
  - [ ] Dev seed sets *placeholder* Lab900 fields (VAT, address, IBAN,
        contact_email) marked as such, so the document fields aren't
        empty in dev. Marked clearly so the user knows to overwrite.
- [ ] **Polish:**
  - [ ] Header service-period inputs look like the existing dashed-
        underline period selector — no boxy native date icons.
  - [ ] Bottom settings block reshaped to feel like an invoice footer
        (less "form panel", more "document").
  - [ ] Mobile: invoice draft form lays out reasonably under 600px wide
        (single column, totals visible without horizontal scroll).
  - [ ] Quick sweep of the home page on mobile.
- [ ] **System tests** (Capybara, headless if possible):
  - [ ] Capture → receipt show → Edit → update → back to show.
  - [ ] Home tray classify (inbound doc → folder pill).
  - [ ] Invoice draft: edit a line, see live total, change tax to IVA 21,
        see IVA row appear; auto-save round-trip.
- [ ] `bin/ci` green; system tests in CI if headless works in the
      environment, otherwise documented for local run.
- [ ] Punch list of *browser-only* checks the user must drive, kept short.

## Bugs identified from 2026-05-13 screenshot

1. **Stale `client_name` snapshot on the draft Send button** — the
   `display_client_name` helper currently falls back to the snapshot before
   the live client. For drafts/approved, always read live; only frozen on
   sent/paid.
2. **No totals breakdown on the draft form** — `_totals_block.html.erb`
   is only rendered in the `else` (sent) branch of `invoices/show.html.erb`.
3. **Empty client VAT / address / IBAN in the document body** — the dev
   seed inserts Lab900 with only `country`, `default_tax_treatment`,
   `default_payment_terms_days`. The fixture has full data but the dev DB
   doesn't.
4. **Bottom "TAX TREATMENT / PAYMENT TERMS / IBAN / NOTES" stack reads as
   a settings panel** — contradicts the "blend with the work" direction.
5. **Header date inputs render as native date pickers** — visually noisy
   compared to the dashed-underline aesthetic of the period selector.

## Steps

1. **Fix display_client_name** for drafts → live client name. → verify: integration test.
2. **Render totals block in draft view** above the settings block. Wire it to the Stimulus live total so it updates as you type. → verify: integration test asserts elements present on draft; system test asserts text update.
3. **Normalize blank tax_treatment**: `before_validation` sets `tax_treatment = nil if tax_treatment.blank?`. → verify: model test.
4. **Improve dev seed for Lab900**: set placeholder VAT/address/IBAN/email with obvious "[set this]" hints. Keep the seed idempotent. → verify: `rails db:seed` then visual eyeball.
5. **Restyle service-period inputs**: minimal styling, no boxy borders, dashed underline on hover/focus to match the existing aesthetic. → verify: by eye + CSS audit.
6. **Reshape the settings block** into a footer-feel block: smaller labels, inline rows where space allows, less form-panel weight. → verify: by eye.
7. **Mobile sweep**: invoice form + home + receipt edit. Single column under 600px, no horizontal overflow, touch-friendly target sizes. → verify: by eye in browser, plus a Capybara test at narrow viewport if feasible.
8. **System tests** for the three golden paths above (skip the ones that need real Selenium if the test env doesn't support it). → verify: tests pass headlessly.
9. **Punch list** for the user (what I can't drive): keyboard flow, real iOS Safari layout, "actual click feels", anything else worth a human eye.
10. **bin/ci + commit.** → verify: green; commit `feat(stabilize-ui): bug sweep + totals on drafts + golden-path system tests`.

## Status

🟡 in progress

## Notes

- Per CLAUDE.md I cannot fully sign off UI changes without browsing — so
  this milestone explicitly ends with a punch list rather than a "🟢 done"
  claim. The user marks it green after their browser pass.
- System tests with Capybara + headless Chrome are part of the Rails 8.1
  default stack — `bin/rails test:system` should just work. If they don't,
  defer the system-test items and note it in the commit.
- A real Clients edit screen (`/settings/client`) is its own milestone if
  the user wants one; this milestone only fixes the visible "I can't see
  my own data" symptom with a seed improvement.

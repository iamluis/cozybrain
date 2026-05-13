# 0015 — ledger visual (design system implementation)

## Goal

Implement `design-system.md` ("Ledger") in `application.css` and apply it
across the app, after `0014-proof-ledger` settles the names + states. By
the end, the invoice, receipt, home, and tray surfaces use the documented
tokens, mono-numbers, and document-feel layout.

## Why

User feedback (2026-05-13): *"so yeah I want a cooler design, something new
but functional if there are any trends and there should be a design system
written out. for eg accounting numbers monospace, etc etc"*

Design system is written (`design-system.md`). This milestone is the
implementation pass.

## Success criteria

- [ ] All tokens from `design-system.md` live in `application.css`
      (color, type, spacing, radius). The old token names are deprecated
      via CSS aliases until usages migrate.
- [ ] Mono numbers ship via the `--mono` stack on every value listed in
      "Where mono is used" in `design-system.md`. Verified by reading the
      headless-Chrome screenshot.
- [ ] The invoice document surface re-renders as a document (thin top/
      bottom rules, no card frame) rather than a rounded card. Other
      surfaces (home, tray, receipts) get the matching feel but stay
      practical (the home stream stays card-bordered because it's a
      multi-row list, not a single document).
- [ ] Status pills replaced with small-caps text where the design system
      mandates ("DRAFT" inline instead of a pill, etc.).
- [ ] One primary umber accent appears on the primary action button only;
      everywhere else is neutral.
- [ ] Existing tests stay green; system test screenshots confirm the visual
      pass on both desktop and 600px-wide mobile.

## Steps

1. **Tokens block** in CSS top, organized in this order: tokens → resets →
   typography → utilities → components.
2. **Apply mono** to every `.num`-shaped value via either a `.num` utility
   or selectors on existing classes. Audit by grepping for amounts /
   numbers in views.
3. **Document-shape** for invoices: drop the rounded card, use full-width
   surface with thin top/bottom rules and generous padding.
4. **Pills → small-caps text** where the system mandates.
5. **Buttons** restyled to the three documented variants.
6. **Tray + stream** re-styled to match the new tokens.
7. **Mobile sweep** at 600px screen size via the system-test harness.
8. **Capture screenshots** of every key surface before/after; attach
   summary to commit.

## Status

🔴 not started

## Notes

- Block on 0014 — implementing visual changes before names/states settle
  causes rework.
- "Ledger" is the name; if the user wants a different name later, it's
  trivial to change in `design-system.md` and the CSS-token namespace.

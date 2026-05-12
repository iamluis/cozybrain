# 0010 — stream + tray shell

## Goal

Replace the page-shaped UI (separate `/`, `/invoices`, `/review`) with a single
**stream + tray** surface. The stream is a passive, read-only scroll of what
happened. The tray is a tiny pile of things only Luis can decide. No menus,
no folders to click into, no separate review page.

## Why

User feedback (verbatim, 2026-05-12): *"the ui should be a big prio, think
outside the box"* — chose Stream + Tray after a four-way fork. The earlier
prior: *"an interface that blends to the info and the work and not the other
way around"* and *"home should be some kind of list of everything that
happened over time"* and *"I shouldn't feel stressed about inputing stuff all
the time"*.

The stream is the *trust* surface (everything is taken care of). The tray is
the *attention* surface (these few items, no more, want a finger).

## Success criteria

- [ ] `/` renders stream (left/main) + tray (right/aside) in a single page.
- [ ] Stream shows day-grouped Filings (filed only) + bank transactions + invoice sends.
- [ ] Tray shows: low-confidence inbound docs (`Filing#needs_review?`) + draft invoices + unmatched bank transactions (capped at 12; overflow indicator).
- [ ] Tray items have one-tap inline actions:
  - inbound doc → "expenses / tax / corporate / bank" pills → moves it to filed in that folder; item disappears from tray.
  - draft invoice → "send" pill (and a quieter "edit" that links to invoice detail).
  - unmatched bank txn → "match" affordance (defer full match UI to later; v1 just shows it).
- [ ] Tray action returns a Turbo Stream that removes the tray item and prepends a stream entry. Page does not reload.
- [ ] Empty stream and empty tray both have calm, non-pushy copy.
- [ ] Mobile: tray collapses behind a top-of-page "Tray · 3" pill. Tap to slide over.
- [ ] `/review` route + controller + view gone.
- [ ] `bin/ci` green.

## Steps

1. **Renumber follow-on milestones (0011 folder-sync, 0012 weekly-pulse, 0013 holded-adapter, 0014 deployment-kamal). Absorb the old 0012 needs-review entirely.** → verify: `ls pm/` shows no gaps, no `0010-needs-review.md`.
2. **Build `Home` aggregate model** at `app/models/home.rb` — returns `#stream_events_by_day` and `#tray_items`. Compose from existing scopes (`Filing.filed`, `Filing.needs_review`, `Invoice.draft`, `BankTransaction.unmatched`). → verify: model test asserts each section is populated correctly from fixtures.
3. **`HomesController#show`** at root. Move `root` route from `pages#home` (landing) and put the public landing back behind `unauthenticated`. → verify: signed-in user gets `/` = home; signed-out gets landing.
4. **Stream partials**: reuse `_filing_entry`, `_bank_transaction_entry`. Add `_invoice_send_entry` for invoice events (created via timeline event row when invoice flips to `sent`). → verify: stream renders all three event kinds.
5. **Tray partials**: `_tray_inbound_doc`, `_tray_draft_invoice`, `_tray_unmatched_transaction`. Each is a `<turbo-frame>` so individual items can swap independently. → verify: each renders with the correct inline pills.
6. **TrayController actions**: `POST /tray/inbound_docs/:filing_id/classify` (param: folder) → calls `Filing#classify_into!(folder)` → returns Turbo Stream removing tray item + prepending stream entry. `POST /tray/invoices/:id/send` is the existing `send_to_client`, just wired to return Turbo Stream. → verify: controller test exercises happy path of each.
7. **Layout reshape**: home layout is a CSS grid (`grid-template-columns: 1fr 22rem` desktop; single column mobile). The tray on mobile is a `<details>` element controlled by a top pill — no JS until proven necessary. → verify: by eye on iPhone-ish width and laptop width.
8. **Delete /review**: `git rm` reviews controller, view, route, helper, tests. Update `app.html.erb` nav to drop the Review link (tray replaces it). → verify: routes have no `/review`; nav has Capture + Invoices only.
9. **CSS**: extend `application.css` with `.home`, `.tray`, `.tray__item`, `.tray__pill`, `.stream`, `.stream__day`. Tokens stay the same. Don't restyle global components. → verify: home looks unified, not bolted-on.
10. **Tests**: home model test, home controller test, tray controller test, system test for "click tray pill → item moves to stream". → verify: `bin/rails test` + `bin/rails test:system` green.
11. **`bin/ci` and commit.** → verify: green, then `feat(stream-tray): single-surface home — stream of done, tray of decisions`.

## Status

🟢 done

## Notes

- The tray is intentionally capped. If something is in the tray it deserves a finger; if too many things are in the tray, the tray is broken, not bigger.
- Inline tray actions are *server*-rendered Turbo Streams. No Stimulus controller until v1 proves the need.
- Bank-transaction matching UI is *not* in this milestone — v1 shows the unmatched row, an explicit affordance lands later (split out as a follow-on milestone if needed).
- `Filing#classify_into!(folder)` is the missing primitive — adds a tiny method to the model. No service object.
- "What blends to the work" check: the user should be able to land on `/`, see today's activity, glance at three items in the tray, tap each one, and be done. No tab-switching, no menus.

# 0003 — Capture flow (mobile)

## Goal

A phone-friendly `/receipts/new` page where Luis types an amount, optionally snaps a photo, and saves. Post-save: a small confirmation with "Add another" / "Done". Each save creates a `Receipt` + `Filing` in one transaction. Auth-gated.

## UX (confirmed)

- **Amount-led layout.** Big amount input is the centerpiece. Photo is a secondary "📷 Photo" button. Date defaults to today (small chip). Vendor / country / note below. Sticky "Save → next" at bottom.
- **Post-save confirmation page.** Shows summary card (amount, vendor, date) + "Add another" and "Done" buttons. Honest about what was captured.

## Success criteria

- [x] Routes: `resources :receipts, only: [ :new, :create, :show ]`.
- [x] `GET /receipts/new` requires auth; unauthenticated redirects to sign in.
- [x] `GET /receipts/new` when signed in renders the amount-led form (200, contains expected fields, `enctype="multipart/form-data"`).
- [x] `POST /receipts` with valid params creates a `Receipt` + `Filing` in one transaction, with folder=`expenses`, source=`capture`, status=`pending`, period from `paid_on`, `received_at` = now.
- [x] `POST /receipts` with invalid params re-renders new (422).
- [x] `GET /receipts/:id` renders summary with "Add another" link to `new_receipt_path` and "Done" link to root.
- [x] Receipt model accepts `amount` as a euros decimal (virtual attribute), converted to cents before validation. Form posts `amount`, not `amount_cents`.
- [x] `bin/ci` green.

## Steps

1. Add `attribute :amount, :decimal` virtual + `before_validation` cents conversion + `COUNTRIES` constant to `Receipt`. → verify: existing receipt tests still green.
2. Add route `resources :receipts, only: [ :new, :create, :show ]`. → verify: `bin/rails routes | grep receipt`.
3. `ReceiptsController` — new/create/show. `create` builds nested Filing. → verify: controller test.
4. Views — `new.html.erb` (amount-led form) and `show.html.erb` (confirmation card). Tailwind only. → verify: form posts to `/receipts`, file input has `capture="environment"`.
5. Controller test — five cases above. → verify: `bin/rails test test/controllers/receipts_controller_test.rb` green.
6. `bin/ci` → verify: exit 0.
7. Commit.

## Notes

- OCR is stubbed in this milestone. Photo is stored as `original_photo` Active Storage attachment; field auto-fill comes in milestone 0004 (Holded integration).
- No Stimulus controller in v1. Native file input + camera capture attribute + Tailwind are enough.
- No batch-mode local queue. The "Add another" button on the confirmation page covers it.
- Country: hardcoded shortlist (`ES BE FR NL DE PT IT GB US`) in a `Receipt::COUNTRIES` constant. Free text would invite typos; an ISO library would be a third-party dep.
- **Result:** 41 tests, 153 assertions, 0 failures. `bin/ci` green.
- Note lives on `Filing.note`, not `Receipt`. The form keeps the field under `receipt[note]` for ergonomics; the controller has a `filing_note` helper that pulls it out before assigning the rest to Receipt.

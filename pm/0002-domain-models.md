# 0002 — Domain models (recordables / Filing)

## Goal

The core nouns from `brain.md` exist as ActiveRecord models with DB constraints, fixtures, and unit tests. Pattern: **recordables** — a single `Filing` wrapper carries cross-cutting filing/sync/review behavior, while each *kind* of filable thing has its own bespoke table.

## Why recordables, not STI or naive polymorphism

Multiple things end up in the gestoría folder (paper receipts, emailed SaaS invoices, bank statements, tax docs, issued invoices). They **share**:

- Where they go in the folder tree (`folder`, `period_year`, `period_month`, `period_quarter`).
- Filing status (`pending` / `filed` / `needs_review`).
- How they arrived (`source`: capture / email / holded_sync / manual).
- A Holded reference (`holded_ref`).
- Trashing, notes, search.

They **differ** in bespoke data — a receipt has an OCR-extracted vendor and amount; an issued invoice has line items and a sequential number; an email-received PDF has none of that.

- **STI** = one wide `documents` table with mostly-null columns. Awkward for line items.
- **Naive polymorphism on every cross-cutting query** = N union queries for "needs review", "filed this week", folder sync.
- **Recordables** = one `Filing` row per thing, `belongs_to :filable, polymorphic: true`. Cross-cutting queries hit one table. Bespoke data stays in the right place.

This is the DHH/Basecamp pattern (`Recording` wrapping `Message`, `Todo`, etc.). We call it `Filing` because we file things, not record them.

## Schema

```
filings
├── id
├── filable_type / filable_id          # polymorphic
├── user_id                            # FK -> users (always Luis in v1)
├── folder           string  NOT NULL  # issued|expenses|bank|tax|corporate|payroll
├── period_year      int     NOT NULL
├── period_month     int                # 1-12, NULL for corporate
├── period_quarter   int                # 1-4, only for tax sometimes
├── status           string  NOT NULL  # pending|filed|needs_review
├── source           string  NOT NULL  # capture|email|holded_sync|manual
├── received_at      datetime NOT NULL
├── filed_at         datetime
├── trashed_at       datetime
├── holded_ref       string  unique-when-present
├── note             text
├── timestamps
└── indexes: [filable_type, filable_id] unique; [user_id, status]; [folder, period_year, period_month]; holded_ref unique

receipts                              # filable
├── id
├── vendor               string
├── amount_cents         int           NOT NULL
├── currency             string  default "EUR"  NOT NULL
├── paid_on              date          NOT NULL
├── country              string                  # ISO 3166 alpha-2
├── ocr_confidence       float
└── has_one_attached :original_photo, :certified_pdf

received_documents                    # filable: emailed PDFs, statements, tax docs, corporate
├── id
├── kind          string NOT NULL     # email_invoice|bank_statement|tax_doc|corporate|other
├── sender        string              # email address or "Holded sync"
├── subject       string
└── has_one_attached :original

issued_invoices                       # filable
├── id
├── client_name          string NOT NULL
├── number               string NOT NULL UNIQUE
├── issued_on            date
├── amount_cents         int    NOT NULL
├── currency             string default "EUR" NOT NULL
├── period_year          int    NOT NULL
├── period_month         int    NOT NULL
├── invoice_status       string NOT NULL  # draft|approved|sent|paid
├── verifactu_ref        string
└── has_one_attached :pdf

issued_invoice_line_items
├── id
├── issued_invoice_id    FK NOT NULL
├── position             int NOT NULL
├── description          string NOT NULL
├── quantity             decimal(10,2) default 1 NOT NULL
├── unit_amount_cents    int    NOT NULL
└── timestamps

bank_transactions                     # NOT filable — money flow, not a document
├── id
├── posted_on            date  NOT NULL
├── amount_cents         int   NOT NULL          # signed
├── currency             string default "EUR" NOT NULL
├── description          string
├── holded_ref           string NOT NULL UNIQUE
├── matched_filing_id    FK    nullable           # links to a Filing once matched
└── timestamps
```

`needs_review` is **a Filing status**, not a folder. The folder sync layer (milestone 0006) puts `status: needs_review` into the `_Needs Review/` directory regardless of `folder`.

`ReviewItem` from the original sketch is dropped — "needs review" is a query (`Filing.needs_review` ∪ `BankTransaction.unmatched`), not a table. Karpathy §2.

`Setting` is also dropped — Holded API key and gestoría email live in Rails encrypted credentials. Re-add only if a real runtime-mutable setting appears.

## Models

- `Filing` — the wrapper. Validates required fields. Enums for `folder`, `status`, `source`. Scopes: `needs_review`, `filed`, `for_period(year, month)`, `untrashed`.
- `Filable` (concern) — `has_one :filing, as: :filable, dependent: :destroy, autosave: true`, plus a `filing_or_build` helper. Each filable model `include Filable`.
- `Receipt`, `ReceivedDocument`, `IssuedInvoice` — each `include Filable`, declare attachments, declare own enums.
- `IssuedInvoiceLineItem` — belongs_to invoice, validates position uniqueness within invoice, total helper.
- `BankTransaction` — standalone. `belongs_to :matched_filing, class_name: "Filing", optional: true`. Scope `unmatched`.

## Success criteria

- [x] Migrations created and applied. `db/schema.rb` shows the tables and indexes.
- [x] All models load (`bin/rails runner "puts Filing.column_names"` works).
- [x] Fixtures exist for each model in `test/fixtures/`. Realistic-but-minimal.
- [x] Each filable model has a fixture **with a matching Filing fixture** (so `receipts(:lab900_dinner).filing` works in tests).
- [x] Unit tests for each model cover: required validations, enum behavior, key association, one happy-path scope.
- [x] `Filing#needs_review?`, `BankTransaction.unmatched` work as scoped.
- [x] `bin/ci` green.

## Steps

1. Generate migrations (don't use `bin/rails g model` for filable models — write the migrations directly to keep them clean). → verify: `bin/rails db:migrate:status` shows all up.
2. Write `Filing` + `Filable` concern. → verify: bin/rails runner "Receipt.include?(Filable)" prints true.
3. Write each filable model + enums. → verify: schema check.
4. Write `BankTransaction` + `unmatched` scope. → verify: schema check.
5. Fixtures for each model. → verify: `bin/rails db:fixtures:load` succeeds.
6. Tests per model. → verify: `bin/rails test` green.
7. `bin/ci` → verify: exit 0.
8. Commit.

## Notes

- Money: `amount_cents :integer`. No Money gem yet. Helper `def amount; amount_cents / 100.0; end` if needed.
- Currency: ISO 4217 string, defaults to "EUR". Don't validate against a list yet.
- Active Storage attachments declared on the filable models, not Filing. Filing is *metadata*, not file storage.
- Polymorphic `filable_type` stores `"Receipt"`, `"ReceivedDocument"`, `"IssuedInvoice"`. No STI, no abstract base class.
- Holded webhooks (later milestone) will mutate Filing.holded_ref and Receipt#certified_pdf.
- **Result:** 36 tests, 113 assertions, 0 failures. `bin/ci` green.
- Required `bin/rails active_storage:install` (not in Rails 8 default generator).
- Fixture gotcha: `matched_filing: foo (Filing)` syntax is for *polymorphic* refs only; plain `belongs_to` needs just `matched_filing: foo`.

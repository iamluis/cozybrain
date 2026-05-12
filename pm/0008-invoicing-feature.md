# 0008 — Invoicing feature (no provider yet)

## Goal

The monthly invoice flow from `brain.md` Flow 3, end-to-end, *without* a real provider. The provider seat is filled by `Adapter::Null::InvoiceIssuer` (synthetic submission + fake VeriFactu ref + locally-generated PDF). When Holded is added in 0013, swap one binding and the same flow goes live.

## UX direction

This is the first milestone where we hold ourselves to a new UX bar. Working notes:

- **No jargon. No names to learn.** Don't call it "VeriFactu", don't call it "the issuer", don't surface enum values. Use the verbs of the work: *draft*, *review*, *send*, *sent*.
- **Blend with the info and the work.** The page IS the invoice. Editing happens in place — typing in a line item *is* the line item. No modal dialogs, no field labels that float in space when there's already a clear column header.
- **Nimble.** Open → see what came over from last month → tweak one number → tap *Send*. Three seconds, no thinking.
- **New.** Don't ship a generic CRM-style "invoice form". The invoice is a document — it should look like the document, even while you're editing. The act of approving should feel like signing, not submitting a form.
- **Calm on success.** No celebration. The invoice quietly slides into the timeline as "sent · €8,000". Done.

If a UX choice serves the work (Luis getting to "sent" without thinking), keep it. If it serves the interface (a "save" button because there's always a save button), kill it.

## Behaviour

1. **Draft pre-fill.** A recurring Solid Queue job (Rails 8.1 `solid_queue:recurring`) nudges around the 28th: clones last month's `IssuedInvoice` + line items into a new draft for the new period.
2. **Review surface.** `/invoices` shows the current draft prominently with past invoices below it, ordered by period. The draft is editable in place — there is no separate "edit" page.
3. **Approve & send.** A single primary action sends. That action enqueues an `Operation(kind: "issue_invoice", adapter_name: <bound>)`. The adapter's `_perform` returns the provider ref + VeriFactu ref + PDF URL. On success, IssuedInvoice transitions `draft → sent`, the Filing flips to `filed`, the PDF attaches, and the invoice fades from "draft" into the historical list.
4. **Failure → retry.** Bounded by `Operation.max_attempts`. On abort, the Filing flips to `needs_review` and the invoice page surfaces *why* in plain language ("Couldn't submit — try again later.").

## What requires the spine

- `Port::InvoiceIssuer` (new) with `INPUT_SHAPE` covering `{ invoice_id, period, client_name, line_items, currency }` and `OUTPUT_SHAPE` covering `{ provider_ref, verifactu_ref, pdf_url, sent_at }`.
- `Adapter::Null::InvoiceIssuer` — local PDF render + synthetic refs. Used in dev/test until 0013.
- Binding registered in `config/initializers/runtime.rb`.

## Out of scope

- Real provider integration (0013).
- Multi-client support beyond Lab900 (already accepted in brain.md).
- Time-tracking / hour entry (brain.md §what-the-system-is-not).

## Detail at milestone start.

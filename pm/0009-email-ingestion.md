# 0009 — Email ingestion

## Goal

brain.md Flow 2. Action Mailbox receives forwarded emails at a dedicated address. Each attachment becomes a `ReceivedDocument` + `Filing` via `Port::InboundDocumentReceiver`. Unknown kinds land in `needs_review`.

## What requires the spine

- `Port::InboundDocumentReceiver` with `INPUT_SHAPE` covering `{ from, subject, body, attachments }` and `OUTPUT_SHAPE` covering `{ classified_kind, confidence, suggested_period }`.
- `Adapter::Heuristic::InboundDocumentReceiver` — regex over sender/subject (Ryanair → email_invoice, Santander → bank_statement, …). Concrete enough to be useful in dev/test.
- Later: an LLM-backed adapter for fuzzier classification — added only when justified.

## Result

- Action Mailbox installed (migration + ApplicationMailbox + InboxMailbox).
- `Port::InboundDocumentReceiver` defines the classification contract.
- `Adapter::Heuristic::InboundDocumentReceiver`: regex rules over sender + subject for Ryanair-style invoices, bank statements (Santander/BBVA/N26/Wise), tax docs (gestoría/AEAT/Modelo), corporate docs (Registro/Notaría). Confidence 0.7–0.9 on hits, 0.3 fallback to "other".
- `Dispatcher.KIND_TO_PORT` + `bind_defaults!` extended.
- `InboxMailbox#process` persists one `ReceivedDocument` + `Filing` per attachment (or one for the body if no attachments), then enqueues `deliver_inbound_document` Operations. Persist-then-defer-interpretation pattern.
- `ApplyDeliverInboundDocumentOutcome`: success copies classifier output onto doc + filing; confidence < 0.6 routes to `needs_review`; abort flips filing to `needs_review` with the error.
- 11 new tests: 6 heuristic-adapter classification, 3 inbox-mailbox persistence + enqueue, 2 end-to-end (mailbox → dispatch → outcome → final state).
- 133 tests / 462 assertions / bin/ci green.

## Outstanding

- Real provider for inbound mail (e.g., a Postmark webhook). For now, Action Mailbox supports several ingress paths out of the box — wire that in deployment milestone.
- LLM-backed classifier as a future adapter for low-confidence ("other") cases.

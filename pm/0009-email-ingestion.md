# 0009 — Email ingestion

## Goal

brain.md Flow 2. Action Mailbox receives forwarded emails at a dedicated address. Each attachment becomes a `ReceivedDocument` + `Filing` via `Port::InboundDocumentReceiver`. Unknown kinds land in `needs_review`.

## What requires the spine

- `Port::InboundDocumentReceiver` with `INPUT_SHAPE` covering `{ from, subject, body, attachments }` and `OUTPUT_SHAPE` covering `{ classified_kind, confidence, suggested_period }`.
- `Adapter::Heuristic::InboundDocumentReceiver` — regex over sender/subject (Ryanair → email_invoice, Santander → bank_statement, …). Concrete enough to be useful in dev/test.
- Later: an LLM-backed adapter for fuzzier classification — added only when justified.

## Detail at milestone start.

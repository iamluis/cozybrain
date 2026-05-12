# 0013 — Holded adapter

## Goal

Concrete Holded implementations of every Port whose Null adapter has been driving the app so far. Switching providers happens in `config/initializers/runtime.rb`, not in feature code.

## What ships

- `Adapter::Holded::ReceiptCertifier` — POST receipt photo, poll/webhook for certified PDF.
- `Adapter::Holded::InvoiceIssuer` — POST invoice + line items, receive VeriFactu confirmation + PDF.
- `Adapter::Holded::BankSync` — pull transactions since last sync, idempotent on `holded_ref`.
- A thin HTTP client (`HoldedClient`) using plain `Net::HTTP`. No HTTP gem.
- Encrypted credentials (`Rails.application.credentials.holded[:api_token]`).
- A webhook controller (`HoldedWebhooksController`) translating callbacks into Operation completions.
- Integration tests against recorded fixtures (no live HTTP in CI).

## What stays from before

Every Port assertion (`assert_input!`, `assert_output!`) still applies. Holded responses are *additionally* asserted against the same schemas — same boundary, different adapter behind it.

## Detail at milestone start.

# 0019 — Holded adapter

## Goal

Concrete Holded implementations of every Port whose Null adapter has
been driving the app so far. Switching providers happens by changing
the `Runtime::Dispatcher.bind` calls in
`config/initializers/runtime_bindings.rb` — no feature code changes.

## Why

Per `brain.md` §implementation-notes: Holded is the chosen provider for
VeriFactu compliance, certified receipt digitization, invoice issuance,
and bank-transaction sync. They hold the AEAT-homologated *Declaración
Responsable*, which is the legally hard part. brain's job is the glue
between Luis's preferred surfaces and Holded's API.

## Pre-flight — what you need to provide

The adapter cannot be built (or even meaningfully sketched) without:

1. **Holded account + paid plan with API access**. The free tier
   doesn't expose the API.
2. **API token** — generated in Holded's settings, stored as
   `Rails.application.credentials.holded[:api_token]`.
3. **API documentation** — endpoints, request/response shapes, error
   codes, webhook payload formats. (Holded's API docs at
   developers.holded.com — version-specific.)
4. **Webhook URL** — depends on 0017 deployment. Holded POSTs back
   here on async events (certification complete, VeriFactu cleared,
   etc.). Needs a public HTTPS endpoint.
5. **Test environment** — either a sandbox account or a willingness to
   make small real calls in dev. Without one, we can't verify
   request/response shapes without breaking real data.
6. **VAT-rate + tax-treatment mapping** — Holded has its own enums for
   `intra-EU reverse charge` etc. Need to confirm which Holded value
   maps to each of brain's TAX_TREATMENTS.

## What ships

- `HoldedClient` — thin Net::HTTP wrapper (no HTTP gem, per CLAUDE.md).
  Bearer-auth, JSON in/out, retries with exponential backoff for 5xx,
  raises `Holded::AuthError` / `Holded::RequestError` / `Holded::TransientError`
  per HTTP class. ~80 lines.
- `Adapter::Holded::ReceiptCertifier` — POST receipt photo + paid_on.
  Holded returns a job ID; we poll OR rely on a webhook for the
  certified PDF URL + AEAT submission ref.
- `Adapter::Holded::InvoiceIssuer` — POST invoice + line items +
  tax_treatment. Holded returns provider_ref + verifactu_ref + pdf_url.
- `Adapter::Holded::BankSync` — pull transactions since
  `BankTransaction.maximum(:holded_ref)`-based cursor, idempotent by
  `holded_ref`. New kind: `sync_bank_transactions`.
- `HoldedWebhooksController` (POST /webhooks/holded) — verifies HMAC
  signature, finds the corresponding Operation by correlation_id,
  applies its outcome (succeed!/fail!).
- Integration tests against recorded fixtures saved under
  `test/fixtures/files/holded/*.json`. No live HTTP in CI. We record
  once against the real API during development; replay forever after.

## What stays from before

Every Port's `assert_input!` / `assert_output!` still applies. Holded
responses are *additionally* asserted against the same shapes — same
boundary, different adapter behind it.

## Success criteria

- [ ] `HoldedClient` exists; auth, JSON encode/decode, retry classes
      verified by unit test.
- [ ] Three adapters live under `app/models/adapter/holded/`, each
      with the correct `port_module`, and each verified against
      recorded fixture responses.
- [ ] `Runtime::Dispatcher.bind_defaults!` switches the production
      bindings to Holded; dev/test keep Null. (Env-conditional binds.)
- [ ] `HoldedWebhooksController` round-trip: receive a signed payload,
      complete the matching Operation, verify Filing/Invoice transitions.
- [ ] Smoke test against the real API: capture a real receipt → see
      certified PDF appear; send an invoice → see VeriFactu QR on the
      Holded-issued PDF.
- [ ] `bin/ci` green (all replay-only).

## Steps (sketch — refine after API token in hand)

1. **Credentials**: `bin/rails credentials:edit` add
   `holded: { api_token: "…", webhook_secret: "…" }`. → verify:
   key resolves.
2. **HoldedClient**: HTTP wrapper + error classes + retry. → verify:
   unit test against `WebMock`-style stubs.
3. **Endpoints** documented in code (URL + payload shape per call).
4. **Adapter::Holded::ReceiptCertifier**: POST + poll/webhook strategy
   decided. → verify: replay test.
5. **Adapter::Holded::InvoiceIssuer**: payload mapping (tax_treatment,
   period, line items, client VAT). → verify: replay test.
6. **Adapter::Holded::BankSync**: new kind `sync_bank_transactions` +
   `Port::BankSync` with cursor semantics. Adapter pulls + creates
   BankTransaction rows. → verify: replay test.
7. **HoldedWebhooksController**: HMAC verify, find by correlation_id,
   succeed!/fail!. → verify: controller test with a recorded payload.
8. **Env-conditional bindings**: in production bind Holded adapters; in
   dev/test keep Null. → verify: by inspecting `Runtime::Dispatcher.adapter_for`.
9. **Real smoke test** (manual, with the user's account). → verify:
   end-to-end against the live API in a test invoice.
10. **Commit per step**. → verify: bin/ci green.

## Status

⏸️ blocked on: Holded API access + 0017 deployment (for webhooks)

## Notes

- No HTTP gem. CLAUDE.md rule: stay on Net::HTTP. ~80 lines of code is
  enough for what we need.
- Don't merge the live API token into git, ever. Credentials only.
- The Adapter::Null::* classes stay in the codebase — they remain the
  test/development bindings. Production binds Holded.
- "Switching providers" eventually means switching to a future
  alternative (Verifacti, custom Hacienda integration, etc.) — keep
  the port shapes provider-agnostic. If a Holded-specific field is
  needed in the output, surface it through `output["provider_ref"]`
  as an opaque string, not a Holded-typed object.
- The webhook secret is per-account; HMAC-SHA256 the body, compare to
  the `X-Holded-Signature` header (or whatever Holded uses — verify
  per their docs).

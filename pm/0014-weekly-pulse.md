# 0011 — Weekly pulse

## Goal

The Monday-morning summary from `brain.md` §weekly-pulse: money in, money out, needs attention, running totals. Solid Queue recurring job builds the digest, sends via `Port::Notifier`. Idempotent per ISO week.

## What requires the spine

- `Port::Notifier` (already exists from 0007) with `INPUT_SHAPE = { recipient, subject, body_text, body_html }` and `OUTPUT_SHAPE = { delivered_at, provider_message_id }`.
- `Adapter::Null::Notifier` (from 0007) — logs and returns synthetic id; sufficient for dev.
- Later: `Adapter::Smtp::Notifier` or `Adapter::Postmark::Notifier`.

## Detail at milestone start.

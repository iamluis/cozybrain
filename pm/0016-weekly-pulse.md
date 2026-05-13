# 0016 — weekly pulse

## Goal

Compose and send a brief Monday-morning digest of the week's bookkeeping:
money in, money out (categorized roughly), things needing attention,
month-to-date running totals. Sent via `Port::Notifier`; idempotent per
ISO week. Plus a `/pulse` page where Luis can view the current/next pulse
on demand.

## Why

Per `brain.md` §weekly-pulse: "Once a week, a brief summary of what came
in, what went out, and anything that needs attention. That's the only
scheduled interruption." The user shouldn't have to come to the app to
check on things; the pulse comes to him.

## Success criteria

- [ ] `WeeklyPulse` PORO at `app/models/weekly_pulse.rb` composes the
      pulse for a given ISO week. Exposes:
  - `money_in`         — sum of income (sent invoices) this week
  - `money_out_total`  — sum of expenses this week
  - `money_out_by_kind` — hash of `{ kind => cents }` for rough buckets
  - `needs_attention`  — counts: `open_tray`, `unmatched_bank`,
                         `needs_review`, plus the actual entries
  - `mtd_income`, `mtd_expenses` — month-to-date totals
  - `period_label`     — e.g. "Week of May 12 – May 18, 2026"
- [ ] `Port::Notifier` shape (already declared in 0007) accepts:
      `recipient`, `subject`, `body_text`, `body_html`.
- [ ] `Adapter::Null::Notifier` logs the body; returns
      `{ delivered_at, provider_message_id }` (already exists).
- [ ] `WeeklyPulseJob` (Solid Queue recurring) runs Monday at 08:00 local
      time, creates an `Operation` with kind `send_notification` and
      `correlation_id = "weekly_pulse:YYYY-WW"`, idempotent.
- [ ] `/pulse` route renders the current week's pulse in HTML (the same
      content the email would carry). Useful for "remind me what's
      happening" without waiting for Monday.
- [ ] Tests:
  - WeeklyPulse model: composes correct numbers per ISO week from
    fixtures.
  - WeeklyPulseJob: idempotent — running twice in one week doesn't
    enqueue twice.
  - Integration: GET /pulse renders the digest.
- [ ] `bin/ci` green.

## Steps

1. **Model**: `app/models/weekly_pulse.rb` — takes a `Time` (default
   `Time.current`), computes the bucketed numbers. Pure read; no
   writes. → verify: model test against fixtures.
2. **Helper**: `app/helpers/weekly_pulse_helper.rb` — render-helpers
   for the body. → verify: implicit via integration test.
3. **View**: `app/views/weekly_pulses/show.html.erb` — ledger-styled
   summary, used both for `/pulse` and for the email's
   `body_html` (rendered via `render_to_string`). → verify: by eye via
   snapshot.
4. **Plain-text rendering**: `app/views/weekly_pulses/show.text.erb` —
   plain-text version for `body_text`. → verify: integration test
   asserts both body parts present in the Operation input.
5. **Controller**: `WeeklyPulsesController#show` at GET `/pulse`. →
   verify: integration test asserts 200 + content.
6. **Job**: `app/jobs/weekly_pulse_job.rb` — creates an Operation
   with `kind: "send_notification"` and `correlation_id:
   "weekly_pulse:#{iso_year}-#{iso_week}"`. Skip if an Operation with
   that correlation_id already exists. → verify: job test for
   idempotency.
7. **Recurring**: register the job via Solid Queue's recurring config
   (config/recurring.yml) for "every Monday 08:00 Europe/Madrid".
   → verify: recurring config loads.
8. **`bin/ci` + commit.** → verify: green; commit
   `feat(weekly-pulse): Monday digest composer + scheduled job`.

## Status

🟢 done

## Notes

- The pulse content is *signal only* — no advice, no marketing, no
  "things are fine" reassurance. If a section has zero items, omit it.
- The job sends through the existing `Port::Notifier` / Null adapter.
  Real email (SMTP/Postmark/etc.) is a future adapter swap —
  Holded probably handles email too if we go through their integration.
- `/pulse` page surfaces the same data on-demand. Click-budget: one
  tap from the bottom-nav (no separate nav item; lives under "Home"
  with a small footer link maybe, OR add to nav). v1: route only,
  add nav link if it proves useful.
- Recurring jobs in Solid Queue 0.4+ use `config/recurring.yml`. Verify
  the format on the actual gem version.

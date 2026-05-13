# 0017 — deployment (Kamal 2)

## Goal

Ship brain to a single Linux box with Kamal 2 + Thruster + SQLite on a
persistent volume. Solid Queue workers run inside Puma for now (small
scale, one less moving piece). HTTPS via Kamal proxy + Let's Encrypt.
Litestream backups of the SQLite files to an S3-compatible bucket
sketched in but deferred (need a bucket first).

## Why

CLAUDE.md stack pin: "Kamal 2 to a single Linux box (or small fleet).
Thruster in front for HTTP/2 + asset caching. Encrypted Rails
credentials → Kamal secrets." We've been building locally; this is the
ship-it milestone.

## Pre-flight — what you need to provide

The Kamal config (`config/deploy.yml`) ships with placeholders. Before
`bin/kamal setup` can run, fill these in:

1. **Server**: a fresh Linux box (Ubuntu 22.04 LTS or similar) that you
   can SSH into. Hetzner CX22, DO basic droplet, Tailscale-only host —
   anything that can pull container images. Has Docker installed (Kamal
   can bootstrap this on first run).
2. **Domain**: `brain.<your-domain>` pointed at the box's public IP.
   Lets Encrypt needs the DNS record live before `bin/kamal setup`.
3. **Container registry**: GHCR (free for personal use). Need a GitHub
   PAT with `write:packages` exported as `KAMAL_REGISTRY_PASSWORD`.
4. **Rails credentials**: `bin/rails credentials:edit` and add the
   inbound-email password under `action_mailbox.ingress_password`. The
   `config/master.key` is pulled by `.kamal/secrets`.

## Success criteria

- [ ] `config/deploy.yml` and `.kamal/secrets` filled in (no
      `«FILL»` placeholders).
- [ ] `bin/kamal setup` completes on the target box.
- [ ] HTTPS works on `https://«domain»` — Kamal proxy issues a Let's
      Encrypt cert.
- [ ] Sign in, capture a receipt, send an invoice — full smoke test
      from a fresh browser, not localhost.
- [ ] Solid Queue runs jobs (verify by enqueuing the weekly pulse
      manually: `bin/kamal app exec --interactive --reuse "bin/rails
      runner 'WeeklyPulseJob.perform_now'"`).
- [ ] SQLite files persist across `bin/kamal deploy` — primary, cache,
      queue, cable.
- [ ] Active Storage blobs persist across deploys (receipt photos
      survive a redeploy).
- [ ] (Deferred) Litestream replicates the four SQLite files to S3 on
      an interval. Lands once we pick a bucket.

## Steps

1. **Pre-flight info gathered** from the user (host, domain, registry,
   secrets). → verify: no remaining placeholders in deploy.yml.
2. **Fill in config/deploy.yml** with real values. → verify: by eye.
3. **First deploy**: `bin/kamal setup` (bootstraps Docker, pulls image,
   runs first container, issues cert). → verify: GET / returns 200
   over HTTPS.
4. **Smoke**: capture a receipt; send an invoice; tap match-a-receipt;
   view /pulse. → verify: each flow round-trips.
5. **Persistence check**: `bin/kamal deploy` (a no-op rebuild),
   confirm receipts + invoices survive. → verify: counts match before
   and after.
6. **Action Mailbox inbound**: configure the email forwarder
   (Postmark, SendGrid, or a local catchall) to POST to
   `https://«domain»/rails/action_mailbox/relay/inbound_emails`
   with HTTP basic auth user `actionmailbox` + the password from
   credentials. Send a test email, confirm a ReceivedDocument lands.
   → verify: filing appears in the tray.
7. **Weekly pulse**: confirm the recurring schedule (Monday 08:00
   Madrid) is loaded. → verify: `bin/kamal app logs | grep recurring`
   shows the schedule. Test by triggering manually.
8. **(Deferred)** Litestream accessory.
9. **Commit** the filled deploy.yml (with placeholders kept as
   placeholders if you'd rather not bake host/domain into git — leave
   the values in `.kamal/secrets` env-pulled instead).

## Status

⏸️ blocked on user-supplied host/domain/registry info

## Notes

- Config is set up to run Solid Queue in-process (`SOLID_QUEUE_IN_PUMA=
  true`). If/when job volume justifies it, split out a separate `job`
  hosts block in deploy.yml.
- Tailscale-only deploy is fine — point the domain at the box's
  100.x.x.x IP and skip Let's Encrypt (set `proxy.ssl: false` and use
  the tailscale MagicDNS hostname directly). The hosts allowlist in
  `config/environments/production.rb` would need a Tailscale entry; for
  dev this was added in 0013.
- Litestream is a small accessory; deferred until there's a bucket. For
  now backups = "the volume is on the box's disk." Not enough for
  legally-required retention.
- Volumes are critical: SQLite files MUST be on a persistent volume,
  otherwise every `kamal deploy` wipes the database. Configured as
  `brain_db:/rails/storage` and `brain_storage:/rails/storage_files`.

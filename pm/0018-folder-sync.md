# 0018 — folder sync (gestoría view)

## Goal

The gestoría folder tree from `brain.md` §gestoría-interface, kept
current. A recurring Operation walks `Filing.untrashed`, computes the
right path (year / month / category; `_Needs Review` for
`status: needs_review`), and writes through `Port::FolderSync`. The
local adapter writes to a directory that's already kept in sync by the
user's cloud tool (Dropbox, iCloud, etc.). The gestoría sees a clean
folder structure without ever touching the app.

## Why

Per `brain.md` §gestoría-interface: "The gestoría doesn't use the app.
They access a shared folder that's always organized and current."
This milestone is the writer that keeps that folder current.

## Success criteria

- [ ] `Port::FolderSync` exists (currently sketched in 0007 notes;
      formalise as a real port module). Shape:
      `INPUT_SHAPE = { filing_id: Integer, target_path: String,
                       original_blob_key: String,
                       certified_blob_key: String }`
      `OUTPUT_SHAPE = { synced_at: String, remote_path: String }`
- [ ] `Adapter::Local::FolderSync` writes Active-Storage blobs to a
      configurable root directory (e.g. `~/Dropbox/SLU/`) using the
      brain.md naming convention:
      `«root»/«Folder»/«YYYY»/«MM-Month»/«YYYY-MM-DD»_«slug»_«amount».«ext»`
      Idempotent: re-running with no Filing changes is a no-op.
- [ ] `Filing#target_path` model method returns the destination path
      (testable in isolation).
- [ ] `FolderSyncJob` enqueues one Operation per untrashed Filing
      whose `synced_at` is nil OR older than `updated_at`. Runs every
      15 min via Solid Queue recurring schedule.
- [ ] `Filing.synced_at` column added (datetime, nullable).
- [ ] `needs_review` filings land in `_Needs Review/` so they're
      visible to the gestoría but obviously incomplete.
- [ ] `bin/ci` green.

## Steps

1. **Migration**: add `synced_at` (datetime) to `filings`. → verify: schema.
2. **`Port::FolderSync`** at `app/models/port/folder_sync.rb`. → verify:
   port shape test.
3. **`Filing#target_path`** helper on the model — computes the target
   path string from filable_type + folder + period + filable details.
   → verify: model test for every filable type + needs_review case.
4. **`Adapter::Local::FolderSync`** at
   `app/models/adapter/local/folder_sync.rb`. Reads blob bytes,
   writes to disk at `Rails.configuration.x.folder_sync_root /
   target_path`. → verify: adapter test with tmpdir as root.
5. **Bind by default** in `config/initializers/runtime_bindings.rb`:
   `Adapter::Local::FolderSync` for `Port::FolderSync`.
6. **`FolderSyncJob`**: scans Filings needing sync, enqueues one
   `sync_filing` Operation per filing. Idempotent. → verify: job test.
7. **`ApplyFolderSyncOutcome`** sets `Filing#synced_at` from the
   adapter's output. → verify: model test.
8. **Recurring**: add to `config/recurring.yml`, every 15 minutes.
   → verify: config loads.
9. **`bin/ci` + commit.** → verify: green.

## Status

🟢 done

## Notes

- v1 writes to a local directory; the user puts that directory inside
  Dropbox / iCloud / Drive and the cloud tool handles the actual sync.
  Cheap and reliable.
- The naming convention from brain.md uses ASCII slugs. Need a
  parameterise step for vendor names with accents/spaces.
- File overwrite is acceptable on re-sync — the source of truth is
  the Filing row + its blob, not the file on disk.
- Cleanup of stale files (e.g. when a Filing is trashed) is its own
  step; the v1 port writes only. A `Port::FolderSync#delete` extension
  can come later.

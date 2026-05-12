# 0010 — Folder sync (gestoría view)

## Goal

The gestoría folder tree from `brain.md` §gestoría-interface, kept current. A recurring Operation walks `Filing.untrashed`, computes the right path (year / month / category; `_Needs Review` for `status: needs_review`), and writes through `Port::FolderSync`.

## What requires the spine

- `Port::FolderSync` with `INPUT_SHAPE = { filing_id, path, original_blob_key, certified_blob_key }` and `OUTPUT_SHAPE = { synced_at, remote_path }`.
- `Adapter::Local::FolderSync` — writes to a configurable local directory (Dropbox/iCloud-synced is enough for v1).
- Later: `Adapter::Rclone::FolderSync` or `Adapter::S3::FolderSync` if Luis wants off-laptop replication.

## Detail at milestone start.

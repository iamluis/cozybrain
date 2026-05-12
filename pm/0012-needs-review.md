# 0012 — Needs-review surface

## Goal

A single internal page that surfaces everything waiting on Luis: `Filing.needs_review`, `BankTransaction.unmatched`, `Operation.aborted` (the framework's own dead-letter). One-click resolutions where possible.

## What this milestone is

Pure UI — no new Port. Reads existing scopes, presents them.

May expose a small admin view of recent `Operation`s (failed / aborted) for transparency. That's the only place a regular user ever sees the framework directly.

## Detail at milestone start.

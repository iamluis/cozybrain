# pm/ — project management

Milestone files for `brain`. Read `brain.md` first; this folder is *how* we get there, not *what* we're building.

## Conventions

- One file per milestone: `NNNN-short-slug.md` (zero-padded, ordered).
- A milestone is a unit of value that can ship to `main` and be committed cleanly. If a milestone is taking >1 day, split it.
- Each milestone has these sections:
  - **Goal** — one sentence.
  - **Success criteria** — verifiable bullets. Each maps to a test or a manual check.
  - **Steps** — ordered, each ending with `→ verify: …`.
  - **Status** — `🔴 not started` / `🟡 in progress` / `🟢 done` / `⏸️ blocked`.
  - **Notes** — anything discovered while executing (links, decisions, deferred work).
- Update `Status` and check off step boxes as you go.
- When a step suggests scope creep, write a new milestone file — don't enlarge the current one.

## Working rhythm

1. Pick the lowest-numbered `🔴` or `🟡` milestone.
2. Re-read `brain.md` for the relevant section.
3. Execute steps in order. Run `bin/ci` (once it exists) before each commit.
4. Commit when a step verifies green. Commit messages: `feat(<milestone-slug>): <what>`.
5. Mark `🟢 done` and move on.

## Milestone map

| #    | Slug                       | Status        |
|------|----------------------------|---------------|
| 0001 | bootstrap-rails-app        | 🟢 done        |
| 0002 | domain-models              | 🟢 done        |
| 0003 | capture-flow               | 🟢 done        |
| 0004 | landing-page               | 🟢 done        |
| 0005 | navigation                 | 🟢 done        |
| 0006 | timeline-home              | 🟢 done        |
| 0007 | integration-spine          | 🟢 done        |
| 0008 | invoicing-feature          | 🟢 done        |
| 0009 | email-ingestion            | 🟢 done        |
| 0010 | folder-sync                | 🔴 not started |
| 0011 | weekly-pulse               | 🔴 not started |
| 0012 | needs-review               | 🔴 not started |
| 0013 | holded-adapter             | 🔴 not started |
| 0014 | deployment-kamal           | 🔴 not started |

Later milestones are intentionally sketched, not specified. We refine them when we pick them up — speculation now is waste.

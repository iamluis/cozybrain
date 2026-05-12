# 0004 — Landing page

## Goal

Replace the `"It works."` placeholder at `/` with a real, public landing page that gives `brain` a first impression. Quiet and dignified — matches brain.md tone ("invisible by default", "the system should feel like a habit, not a tool"). One brand mark, a one-line description of what the app does, and a Sign in entry. No marketing.

## Why before Holded

The web app has to be coherent as a product before we bolt on integrations. A bare `"It works."` root makes the project feel like scaffolding; Luis will use this every time he opens the URL on his phone. Five minutes of landing-page work earns a lot of dignity.

## Audience

- Luis himself (logged-out state, on phone or laptop).
- Anyone who lands on the URL by accident — should understand it's a personal tool, not a SaaS.

## Success criteria

- [x] `/` renders without authentication (already does).
- [x] If a session is active, `/` redirects to a sensible home (we'll define what "home" is in 0005; for now keep that behavior off — the landing page is public-only, but we don't redirect signed-in users away yet).
- [x] The landing page contains:
  - Brand mark `brain`.
  - A single-line tagline.
  - A short paragraph explaining the scope ("Quiet bookkeeping for a one-person SLU. Captures expenses, files documents, drafts invoices.").
  - A primary "Sign in" button linking to `/session/new`.
- [x] Works on a 360px-wide phone screen without horizontal scroll.
- [x] Works on a 1440px-wide laptop without the content stretching across the screen.
- [x] Existing root page integration test still green (assert title + sign-in link, drop the `"It works."` assertion).
- [x] `bin/ci` green.

## Steps

1. Update `app/views/pages/home.html.erb` with the landing markup. → verify: HTML structure.
2. Add minimal CSS to `application.css` for the landing (probably reuse `.hero` + a couple of additions). → verify: visual.
3. Update `test/integration/root_page_test.rb` to assert the new copy and the sign-in link. → verify: green.
4. `bin/ci` → verify: exit 0.
5. Commit.

## Notes

- No marketing copy. Brain is a personal tool, not a product.
- No nav on this page — that's milestone 0005's job (and only for the *authenticated* shell).
- No images. Brand mark is the wordmark; an SVG icon can come later if needed.
- No JavaScript on this page.
- **Result:** 3 root-page tests pass, 41 total. bin/ci green.
- Deferred to 0005: redirecting signed-in users away from `/`. Without a shell, signed-in `/` showing the landing is still fine.

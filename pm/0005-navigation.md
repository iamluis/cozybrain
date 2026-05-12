# 0005 — Navigation / app shell

## Goal

A coherent authenticated shell so the web app feels like one application instead of a collection of unrelated pages. Top header with brand + nav links + sign-out. Layout wraps every authenticated page.

## Why now

The capture flow already exists (0003). Once a user is signed in, there's currently no way to get back to capture (or to anywhere else) without typing URLs. Even a minimal nav unlocks the rest of the milestones (invoice review, needs-review surface, etc.) since they'll all hang off the same shell.

## Audience

Luis on his phone (primary) and laptop. The phone navigation lives at the bottom for thumb reach; the laptop nav lives at the top.

## Shell shape

```
┌───────────────────────────────────────────────┐
│  brain                            Sign out    │   header
├───────────────────────────────────────────────┤
│                                               │
│  …page content…                               │
│                                               │
├───────────────────────────────────────────────┤
│  📷 Capture   📄 Invoices   ⚠ Review          │   bottom nav (mobile)
└───────────────────────────────────────────────┘
```

On laptop the bottom-nav links are duplicated in the header (right of the brand).

## Success criteria

- [ ] An `app` layout (or modifications to the default layout) is used by every authenticated controller.
- [ ] Public pages (landing, sessions, passwords) do NOT show the shell.
- [ ] Authenticated pages show: brand mark linking to root, nav links (Capture, Invoices, Review), Sign out form (`DELETE /session`).
- [ ] On a 360px phone width, the nav lives at the bottom in a fixed bar with finger-sized targets (≥44px).
- [ ] On a 768px+ width, the bottom nav hides and the header shows the same links.
- [ ] Signed-in users hitting `/` redirect to `/receipts/new` (the primary action) — brain.md implies capture is the main entry.
- [ ] Invoices index and Review pages don't need real content yet — placeholder views with the shell are fine. (Real content lands in 0009 and 0011.)
- [ ] All existing tests still green; new integration tests cover: shell appears when signed in, signed-in root redirects, sign-out works.
- [ ] `bin/ci` green.

## Steps

1. Introduce two layouts: keep the default `application.html.erb` minimal/public; add `app.html.erb` for authenticated pages with the shell. → verify: layout structure.
2. Mark controllers: `ReceiptsController`, `InvoicesController`, `ReviewsController` all `layout "app"`. `PagesController`, `SessionsController`, `PasswordsController` keep the default. → verify: integration test shows the shell on `/receipts/new` and not on `/`.
3. Add placeholder `InvoicesController#index` and `ReviewsController#index` returning empty shells. Routes: `resources :issued_invoices, only: :index` (alias `invoices`), `resource :review, only: :show` or similar. → verify: links work.
4. Add CSS for `.shell`, `.shell__header`, `.shell__nav`, `.shell__bottom-nav`, mobile vs desktop nav swap via media query. → verify: visual.
5. Update `PagesController#home` to redirect to `new_receipt_path` if authenticated. → verify: integration test.
6. Integration tests: shell visible when signed in, sign-out works, signed-in root redirect, public pages don't show shell.
7. `bin/ci` → verify: exit 0.
8. Commit.

## Notes

- Use plain CSS media queries for the responsive swap; no JS needed.
- The "Invoices" and "Review" placeholder views are intentionally empty — that's a feature, not a bug. They become real in 0009 / 0011.
- Sign-out is a `<button>` inside a form that POSTs `DELETE /session` (Turbo handles the method override).

# 0001 — Bootstrap Rails app

## Goal

A green, committed Rails 8.1 monolith with the DHH no-build stack wired up, `bin/ci` passing on a hello-world page.

## Success criteria

- [ ] `ruby -v` reports 4.0.x (or 3.4.x if 4.0 not installable on this Mac; document why).
- [ ] `bin/rails -v` reports 8.1.x.
- [ ] App boots: `bin/dev` serves `/up` (Rails health check) and a root page returning 200.
- [ ] `bin/rails test` runs and is green (one trivial integration test exists for the root page).
- [ ] `bin/ci` exists (Rails 8.1 default) and is green.
- [ ] `config/database.yml` uses SQLite for dev, test, and production with separate files for primary / queue / cache / cable.
- [ ] Solid Queue, Solid Cache, Solid Cable installed and configured.
- [ ] Propshaft is the asset pipeline. importmap-rails is in the Gemfile. No `node_modules`, no `package.json`, no `bun.lockb`, no `yarn.lock`.
- [ ] Hotwire (Turbo + Stimulus) installed.
- [ ] `bin/rails generate authentication` has been run. `User` + sessions tables exist.
- [ ] Kamal 2 + Thruster present (config not yet pointed at a real host — that's milestone 0010).
- [ ] Repo has a `.gitignore` covering Rails + macOS noise.
- [ ] A single commit captures the green baseline.

## Steps

1. **Verify toolchain.** Check `ruby -v`, `gem list rails`, `which rails`. If Rails 8.1.x is missing, install via `gem install rails -v "~> 8.1"`. → verify: `rails -v` prints `Rails 8.1.x`.
2. **Generate the app.** From `/Users/coruben/dev/cozyedge/`, but the target dir is already `brain/` and has docs in it. Use `rails new brain --force --skip-bundle --database=sqlite3 --skip-jbuilder --skip-test-unit=false --asset-pipeline=propshaft --javascript=importmap --css=` (no css framework). The `--force` keeps our existing `CLAUDE.md`, `brain.md`, `pm/`. → verify: `Gemfile`, `bin/rails`, `app/`, `config/` present; our docs untouched.
3. **`bundle install`.** → verify: `bin/rails -v` works.
4. **Verify defaults.** Confirm Rails 8 generator already includes solid_queue/solid_cache/solid_cable + thruster + kamal. If not, add to Gemfile and `bin/rails solid_queue:install`, `solid_cache:install`, `solid_cable:install`. → verify: `config/queue.yml`, `config/cache.yml`, `config/cable.yml` exist and reference SQLite.
5. **Multi-DB config.** Confirm `config/database.yml` has primary/queue/cache/cable databases. → verify: `bin/rails db:prepare` creates `storage/development*.sqlite3` files.
6. **Authentication.** `bin/rails generate authentication`. Run migrations. → verify: `User`, `Session` tables in schema; `app/controllers/sessions_controller.rb` and friends generated.
7. **Hello root.** Generate `PagesController#home`, point root to it, render "It works." → verify: `bin/dev` serves `/` 200.
8. **First test.** `test/integration/root_page_test.rb` — GET `/`, assert 200 + body contains "It works." → verify: `bin/rails test` green.
9. **`bin/ci`.** Confirm Rails 8.1 generated it (otherwise create per [release notes](https://rubyonrails.org/2025/9/4/rails-8-1-beta-1)). → verify: `bin/ci` exits 0.
10. **Commit.** `git add -A && git commit -m "feat(bootstrap): rails 8.1 app, solid trifecta, auth, hello root"`. → verify: `git status` clean.

## Notes

- The `rails new` step is the only place we accept Rails' generator defaults wholesale. After this milestone, every gem addition needs explicit justification per CLAUDE.md.
- If Ruby 4.0 has compatibility issues with Rails 8.1 on this Mac, fall back to Ruby 3.4.x — note the reason here and revisit later.
- `.ruby-version` should be committed.

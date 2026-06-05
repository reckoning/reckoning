# AGENTS.md

Conventions for AI agents (Claude Code, Cursor, Copilot, etc.) working on
Reckoning. This file is the single source of truth — `CLAUDE.md` just
points here.

## What this app is

Reckoning is a self-hosted invoicing app for freelancers and small
agencies. Customers + projects + time tracking → invoices + offers
rendered as PDFs and emailed.

## Stack

### Current

- **Ruby** 3.4.7
- **Rails** 7.2 LTS (still on `config.load_defaults 7.0`)
- **Postgres** 17 (with hstore), **Redis** 7.4
- **Node** 22 LTS, **pnpm** 10 (never `npm install` directly — there is
  a `preinstall` hook that enforces pnpm)
- **Sidekiq** 7 + sidekiq-cron, sessions/cache via Rails
  `:redis_cache_store`
- **Auth** Devise + devise-two-factor (v6 schema); JWT for API
- **Authz** CanCanCan
- **Templating** ERB (every view; haml + slim removed in Phase 3)
- **PDF** Grover (puppeteer + Google Chrome)
- **Storage** ActiveStorage on DigitalOcean Spaces (S3-compatible) in
  production
- **Frontend toolchain** Vite (`vite_rails`) with TS entrypoints under
  `app/frontend/`, alongside the legacy Sprockets + Terser bundle
  which still ships jQuery / CoffeeScript / AngularJS until Phase 9.
- **CSS** Tailwind 4 via `@tailwindcss/vite` (preflight off so it
  coexists with Bootstrap 3 until Phase 9)
- **JS framework** Hotwire — Turbo Drive owns navigation, Stimulus
  controllers auto-register from `app/frontend/controllers/*_controller.ts`

### Migrating toward

- Container deploy via **Kamal 2** + multi-stage Dockerfile + GHCR
  (runs **alongside Capistrano** until verified; auto-deploy on push
  is currently gated off — see #837).
- Release automation via **release-please** + Conventional Commits.

### Frontend modernization in flight

The frontend is legacy and being replaced. **Don't add new code to the
legacy stack** — if you must touch a screen, prefer the smallest
in-place change. New features go through Vite (TS + Tailwind +
Hotwire). See `docs/frontend-migration-plan.md` for the phased plan.

Done (Phases 1–4 + Phase 5 in progress):

- Phase 1 — Vite installed alongside Sprockets (#859)
- Phase 2 — Tailwind 4 alongside Bootstrap 3, preflight off (#860)
- Phase 3 — every haml/slim template converted to ERB; haml + slim
  gems dropped (#861–#870)
- Phase 4 — Turbo Drive + Stimulus baseline; Turbolinks gone
  (#871, #872)
- Phase 5 — Turbo Frames on CRUD index pages
  (projects #873, offers #874, invoices #875)
- Phase 8 — Cypress 12 → Playwright; cleared the last 11 dev-only
  npm vulns

Still legacy (to be removed in later phases):

- Bootstrap 3 (EOL 2019) + bootstrap-sass + bourbon — Phase 9
- AngularJS (EOL 2021) under `app/assets/javascripts/angular/` —
  Phase 7, after Vue islands (Phase 6) replace timesheet + project
  timers calendar
- jQuery + jquery_ujs — Phase 9 (after the remaining `[data-method]`
  / `[data-notyConfirm]` flows move to Turbo + Stimulus)
- CoffeeScript (`*.coffee` files, `coffee-rails` gem) — Phase 9
- Sprockets `//= require` manifests — Phase 9
- bower-rails — Phase 7
- i18n-js v3 — Phase 10

### Hotwire conventions

- **Turbo Drive** is enabled globally. Opt out with `data-turbo="false"`
  on a link or its container.
- **Turbo Frames** wrap list/filter/pagination regions on index pages
  (see `app/views/{projects,offers,invoices}/index.html.erb`). Frame
  id matches the wrapper on both the initial render and the
  subsequent partial response; the controller doesn't need a special
  branch.
- **`data-turbo-method`** is the Turbo replacement for the classic
  Rails `link_to ..., method: :put|:delete`. Use `data: { turbo_method:
  :put }` in `link_to` calls.
- **`turbo:load → turbolinks:load` shim** in `application.ts` re-fires
  the legacy event so existing CoffeeScript that listens for
  `turbolinks:load` keeps working under Turbo navigation. Delegate
  event handlers to `document` if they need to survive Turbo Frame
  swaps (see `app/assets/javascripts/helpers/noty.coffee` for the
  pattern).
- **Stimulus controllers** live in `app/frontend/controllers/`. File
  `tabs_controller.ts` exporting a default `Controller` subclass
  auto-registers as `data-controller="tabs"`.

## Project structure

```
reckoning/
├── app/
│   ├── controllers/       # Rails controllers (API in api/v1/)
│   ├── models/            # ActiveRecord models
│   ├── views/             # ERB templates
│   ├── helpers/           # view helpers
│   ├── mailers/           # mailers
│   ├── workers/           # Sidekiq workers
│   ├── services/          # service objects (invoice/offer/import logic)
│   ├── validators/        # custom AR validators
│   └── assets/            # legacy Sprockets pipeline (being replaced)
├── config/
│   ├── routes.rb          # main router (delegates to routes/*.rb)
│   ├── routes/            # api_routes, etc.
│   ├── initializers/
│   ├── environments/
│   ├── deploy.yml         # Kamal 2
│   └── deploy.rb          # Capistrano (legacy)
├── db/
│   ├── migrate/
│   ├── data/              # data_migrate migrations
│   └── seeds.rb
├── test/                  # Minitest (fixtures + integration)
│   └── e2e/              # Playwright specs (alongside the Minitest suite)
├── lib/
├── docker/
├── Dockerfile             # multi-stage prod image
└── .github/workflows/     # CI: ruby-lint, ruby-tests, ruby-audit,
                           #     brakeman, seeds, e2e-tests
```

## Essential commands

### Setup

```bash
docker compose up -d                 # postgres + redis on ports 8241/8242
bundle install
pnpm install
bin/setup                            # creates dev + test DBs, seeds, etc.
```

### Development

```bash
foreman start -f Procfile.dev        # Rails + sidekiq + (legacy) assets
```

### Testing

```bash
bundle exec rails test                                    # full minitest suite
bundle exec rails test test/path/to/specific_test.rb      # single file
pnpm test:e2e                                             # playwright
```

The CI runs tests sharded with `knapsack` (4 shards). To run a single
shard locally: `CI_NODE_TOTAL=4 CI_NODE_INDEX=0 bundle exec rake knapsack:minitest`.

### Linting & static analysis (run after EVERY change)

```bash
bundle exec standardrb --fix                  # Ruby — required before commit
bundle exec brakeman --no-pager --exit-on-warn  # Security static analysis
bundle exec bundle-audit check                # CVE check
```

All three are wired as required PR gates in CI. They WILL fail your PR.

### Deploy (during the Capistrano → Kamal transition)

```bash
# Legacy path (currently the source of truth)
bundle exec cap live deploy

# New path (disabled by default until verified)
bundle exec kamal deploy -d live
```

The auto-deploy on push-to-main is **disabled** (workflow has
`if: false && ...` since #837) until the Kamal cutover.

## Conventions

### Ruby

- **`standardrb` is the style** — no rubocop config, no opinions to
  argue. Run `bundle exec standardrb --fix` after touching `.rb` files
  or CI rejects the PR.
- snake_case files/methods/variables, CamelCase classes/modules
- Prefer single quotes unless interpolating
- `# frozen_string_literal: true` at the top of every `.rb` file
- Service objects under `app/services/` for non-trivial business logic
- Sidekiq workers under `app/workers/` (not `app/jobs/` — predates Rails'
  `ActiveJob::Base` convention)

### Rails

- **Strong params everywhere** — Brakeman gates this
- **CanCanCan abilities** in `app/models/ability.rb`; admin scope is
  `setup_admin_abilities` (only added when `user.admin?`)
- **Devise** for authentication; JWT helper at `lib/json_web_token.rb`
  for API. There IS a `Devise::Strategies::JWT` extension in
  `config/initializers/core_extensions/devise/strategies/jwt.rb` that
  runs on every request when an `Authorization: Token ...` header is
  present.
- **i18n** — every user-facing string goes through `I18n.t(...)`.
  Default locale is `:de`, available locales is `[:de]`. English files
  exist as `~`-only stubs (translation pipeline pending).

### Database

- **Migrations**: schema migrations under `db/migrate/`. Data
  migrations (backfills, etc.) under `db/data/` via the `data_migrate`
  gem. Run together: `rails db:migrate:with_data`.
- **N+1 vigilance**: `bullet` is enabled in dev/test. If it fires,
  fix the query — don't silence it.
- **Indexes**: any new `belongs_to` adds an index.

### Tests

- **Minitest** with `minitest-rails` (NOT RSpec — don't try to convert).
- Fixtures under `test/fixtures/*.yml` (NOT FactoryBot — for now).
- `DatabaseCleaner` strategy is `:transaction` per integration test.
- `ActiveRecord::Migration.check_all_pending!` in `test/test_helper.rb`
  ensures the schema is current before the suite runs.

### CI gates (all required to pass)

- `ruby-lint` — `standardrb --format progress`
- `ruby-tests` — 4-shard knapsack minitest
- `brakeman` — `--exit-on-warn` (baseline ignore list is currently
  empty as of #855)
- `ruby-audit` — `bundle-audit check` (no ignores; sinatra ReDoS
  cleared by #821)
- `seeds` — `rails db:seed` must succeed against a fresh DB
- `e2e-tests` — Playwright
- The `deploy` job is currently `if: false && ...` (gated off until
  Kamal cutover)

## Git workflow

### Branch names

```
feat/<short-desc>     # new functionality
fix/<short-desc>      # bug fix
refactor/<short-desc> # internal change, no behavior diff
chore/<short-desc>    # tooling, ci, deps
docs/<short-desc>     # docs only
```

### Commit messages — Conventional Commits (required)

Format:

```
<type>(<scope>): <short summary>

<body — optional>
```

Types accepted by the PR title linter (`amannn/action-semantic-pull-request`):
`feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `build`, `ci`,
`perf`, `style`, `revert`.

release-please uses these to drive automatic CHANGELOG + version
bumps. `feat:` → minor, `fix:` → patch, breaking changes (`feat!:` or
a `BREAKING CHANGE:` footer) → major.

PR title also follows this format — the title-lint workflow checks it.

## API workflow

- API controllers live under `app/controllers/api/v1/`.
- Routes in `config/routes/api_routes.rb`.
- Auth is the JWT strategy: pass `Authorization: Token token="<jwt>"`.
- JSON serialization via `jbuilder` views (`*.json.jbuilder`).

## Debugging protocol

Before reaching for changes:

1. **Reproduce locally** — get a failing test or a curl that hits the bug.
2. **Read the trace** — full error + relevant call sites, not just the
   first line.
3. **Form a hypothesis** — write it down before editing.
4. **One change at a time** — easier to bisect when the next test fails.
5. **No drive-by refactors** — a bug fix is a bug fix.

## Agentic best practices

### Before writing code

- Read the existing pattern. If the existing code does X one way, do
  it that way unless there's a clear reason not to.
- Check the migration-in-flight context above. Don't add new code to
  the legacy frontend stack (Sprockets/AngularJS/CoffeeScript/Bootstrap 3).
- Read `.cursor/rules/` files if any exist (none today; long-form
  conventions live in this file).

### While writing

- Keep diffs small. A "fix one thing" PR is much easier to land than
  a "fix one thing and also clean up everything around it" PR.
- New features need tests. `test/` is sparse — don't make it sparser.
- Use feature flags via env vars for experimental code paths
  (Flipper isn't installed yet).

### After writing

- `bundle exec standardrb --fix` on any touched `.rb` file
- `bundle exec brakeman --exit-on-warn` if you touched controllers,
  models, views, routes, or initializers
- `bundle exec bundle-audit check` if you touched the Gemfile
- For changes that affect the running app: smoke-test in a browser
  before claiming "done"

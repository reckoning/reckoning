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
- **Templating** Vue 3 SFCs for every screen; ERB for the shell, the
  mailers, the PDF templates and the error pages
- **PDF** Grover (puppeteer + Google Chrome)
- **Monitoring** AppSignal — the Ruby agent covers Rails + Sidekiq
  (`config/appsignal.rb`), and `@appsignal/javascript` covers the Vue
  SPA. Replaced Sentry.
- **Storage** ActiveStorage on DigitalOcean Spaces (S3-compatible) in
  production
- **Frontend toolchain** Vite (`vite_rails`) with TS entrypoints under
  `app/frontend/`. The legacy Sprockets bundle is still built, but only
  the five remaining ERB pages load it — it is what keeps jQuery,
  Bootstrap's JS and the last CoffeeScript alive.
- **CSS** Tailwind 4 via `@tailwindcss/vite`. `spa.css` carries its own
  preflight and a set of `bs-*` classes measured off the
  server-rendered screens; `tailwind.css` omits preflight so it cannot
  disturb Bootstrap 3 on the pages that still use it.
- **JS framework** Vue 3 + vue-router, which owns the whole path space.
  Turbo Drive and Stimulus are still loaded by the legacy bundle and
  matter only on the five ERB pages.

### Migrating toward

- Container deploy via **Kamal 2** + multi-stage Dockerfile + GHCR
  (runs **alongside Capistrano** until verified; auto-deploy on push
  is currently gated off — see #837).
- Release automation via **release-please** + Conventional Commits.

### Frontend modernization in flight

The app is a Vue SPA. Every screen behind a login has moved; what is left
server-rendered is deliberate or not yet decided. `docs/vue-spa-migration-plan.md`
is the plan of record — `docs/frontend-migration-plan.md` describes the
phases that preceded it (Vite, Tailwind, ERB conversion, Turbo, Vue
islands) and is history.

**Where things are**

- `app/frontend/pages/<domain>/` — the screens, one folder per domain,
  with their Vitest specs beside them.
- `app/frontend/components/ui/` — the shared `Ui*` components. They are
  measured ports of Bootstrap 3, not a new design system: `spa.css`
  holds the values, with a comment naming the partial each came from.
- `app/frontend/plugins/router.ts` — every route. `meta.requiresAuth`
  gates a screen, `meta.requiresAdmin` re-reads who you are, and
  `meta.backend` swaps the chrome for the admin's own.
- `app/frontend/services/api/` — generated, gitignored, never edited.
- A component that belongs to one screen lives beside it, in that screen's
  `components/`. `app/frontend/islands/` is gone: nothing server-rendered
  mounts a Vue island any more.

**Still server-rendered, on purpose**

- The PDFs (`app/views/invoices/pdf`, `offers/pdf`, `expenses/index.pdf`)
  and the CSV exports. The SPA links them.
- The mailers.
- Sidekiq (`/backend/workers`) and Flipper (`/backend/flipper`).

**No screens are left on the legacy pipeline.** The welcome page, signup
and the three legal documents were the last of them, and the layout they
rendered in is gone. What is still wired up but no longer reached by any
screen — `app/assets/`, the bower bundles, the Turbo/Stimulus entry in
`application.ts`, Tailwind's preflight staying off in `tailwind.css` —
is Phase C's list in `docs/vue-spa-migration-plan.md`, and can now be
deleted in one sweep rather than screen by screen.

### SPA conventions

- **The API comes first, and its schema is the tests.** Declare an
  endpoint in a Minitest DSL spec under `test/integration/api/v1/`, then
  `RAILS_ENV=test rake openapi_ruby:generate` writes `swagger/v1/schema.yaml`
  and `pnpm run generate-api-client` turns it into the hooks under
  `app/frontend/services/api/`. A route and an action without a DSL
  declaration are unreachable from the SPA — that has bitten twice.
- **Rails owns a path or the SPA does.** `config/routes.rb` ends in a
  catch-all that hands every page load to the shell; the list of first
  path segments above it (`api`, `api-docs`, `backend`'s two mounts,
  `cable`, `rails`, `up`) is what the server keeps. A path that answers
  a non-page request — an export, a PDF — is declared before it.
- **A screen's state lives in the URL.** Filters, sorting and paging are
  query parameters, so a filtered list is a link someone can send.
- **Three test layers, and they do different jobs.** Vitest for a
  component's logic against a stubbed adapter, the Minitest DSL specs
  for the contract, Playwright for the flow through a real server. A
  screen port lands with all three.
- **Measure, do not guess, when porting a look.** The server-rendered
  stylesheet is still built: render the old markup against
  `application.css`, screenshot it, and match. Two bugs got through on a
  guess — a chart whose labels wrapped and a tab that had no card.

## Project structure

```
reckoning/
├── app/
│   ├── controllers/       # Rails controllers (API in api/v1/)
│   ├── models/            # ActiveRecord models
│   ├── views/             # ERB: the shell, mailers, PDFs, public pages
│   ├── helpers/           # view helpers
│   ├── mailers/           # mailers
│   ├── workers/           # Sidekiq workers
│   ├── services/          # service objects (invoice/offer/import logic)
│   ├── validators/        # custom AR validators
│   ├── frontend/          # the Vue SPA (pages, components, stores, api)
│   └── assets/            # legacy Sprockets, for the public pages only
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

op signin                            # dev secrets come from 1Password
export OP_ACCOUNT=my.1password.eu
```

No `.env` is needed. `.env.tpl` is committed and holds `op://` references
instead of secrets; `bin/op` resolves them at run time. Machine-specific
overrides (ports, `WORKTREE_SUFFIX`) go in `.env.local`, which is gitignored and
read after the template.

### Development

```bash
bin/dev                               # Rails + sidekiq + vite (see --help)
bin/op rails console
bin/op rake db:migrate
```

Anything needing dev secrets goes through `bin/op`. Commands that don't — tests,
linters, generators — can run directly.

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

### Secrets (Kamal path)

Every Kamal secret comes from the **`Reckoning` 1Password vault** via
`.kamal/secrets-common` and `.kamal/secrets.<destination>`. Those files hold
`op read` calls, not secret material, and are committed on purpose.

```bash
op signin
export OP_ACCOUNT=my.1password.eu

bundle exec kamal secrets print -d live   # verify resolution before deploying
```

CI uses `OP_SERVICE_ACCOUNT_TOKEN` instead of `OP_ACCOUNT`.

Notes:

- `RAILS_MASTER_KEY` decrypts `config/credentials/production.yml.enc`, which
  supplies `secret_key_base`, the devise secrets, mailer credentials **and the
  `active_record_encryption` keys**. A wrong key does not fail loudly — it makes
  every encrypted column read back as garbage.
- `DATABASE_URL`/`REDIS_URL` are built in `.kamal/secrets.live` from the
  Postgres accessory credentials. They resolve over the Docker network
  (`reckoning-db`, `reckoning-redis`) because live is a single node with
  colocated datastores.
- Servers, buckets and the accessory topology are provisioned by
  [reckoning/infrastructure](https://github.com/reckoning/infrastructure).
- The Capistrano path still reads `.env` and `config/credentials/production.key`
  from disk. Both go away with the cutover.

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

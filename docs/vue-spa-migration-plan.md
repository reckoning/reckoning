# Vue SPA + OpenAPI migration plan

Exec plan for moving Reckoning to a **Vue 3 + Tailwind SPA** backed by a
**schema-first JSON API** built with `openapi-ruby`, mirroring the
architecture already proven in [FleetYards](https://github.com/fleetyards/fleetyards).

## Relationship to `docs/frontend-migration-plan.md`

That plan is **Hotwire-first**: server-rendered ERB, Turbo Drive for
navigation, Turbo Frames for partial updates, Vue only as islands on the
two complex screens. This plan replaces that direction from Phase 5
onward. It is a deliberate strategy change, not a continuation.

**What carries over (already landed, still correct):**

| Landed | Still used here |
|---|---|
| Phase 1 — Vite + `vite_rails`, `app/frontend/` | Yes — same bundler, same entrypoint layout |
| Phase 2 — Tailwind 4 via `@tailwindcss/vite` | Yes — preflight gets turned **on** once Bootstrap dies |
| Phase 6a — Vue 3 + `@vitejs/plugin-vue`, islands | Partly — the SFCs become SPA pages/components, `mountIslands` goes away |
| Phase 8 — Playwright + cypress-on-rails bridge | Yes — same e2e runner, specs get rewritten against the SPA |
| Phase 3 — haml/slim → ERB | Mostly sunk cost; only the layouts + mailer templates survive |

**What gets abandoned:**

- Phase 5's Turbo Frames on CRUD index pages (projects #873, offers #874,
  invoices #875, customer edit #888) — the SPA owns those screens.
- Phases 4/5's Turbo Drive + Stimulus as the interactive layer. Turbo and
  the ~9 Stimulus controllers under `app/frontend/controllers/` get deleted
  once their screens are ported.
- Phase 10's i18n-js v4 plan — the SPA ships its own translation bundles;
  i18n-js gets dropped, not upgraded.

Phases 7 and 9 (drop AngularJS / Bootstrap / Sprockets) still happen — they
just happen as a consequence of screens being ported, and are folded into
Phase C below.

**Cost of the pivot:** roughly 2–3 weeks of already-merged Hotwire work
(Phases 4, 5, part of 6a) is discarded. Worth stating up front so the
decision is made with eyes open. The alternative — finishing the Hotwire
plan and *then* rewriting — costs strictly more.

## Why this shape

Reckoning already has a JSON API (`app/controllers/api/v1/`, jbuilder views,
JWT auth), but it is partial — 6 controllers covering customers, projects,
tasks, timers, users, sessions — and hand-maintained with no contract. Its
only consumers were the never-released iOS and macOS tryouts, so it can be
reshaped rather than preserved (see D2).

`openapi-ruby` turns that into a contract-first API where:

- Response/request shapes live in `app/api_components/` as Ruby classes.
- Paths + operations are declared in **integration tests** (minitest DSL),
  so the schema and the test suite are the same artifact — an endpoint
  without a test literally does not appear in the schema.
- `swagger/v1/schema.yaml` is generated and committed.
- `orval` generates a typed `@tanstack/vue-query` + axios client into
  `app/frontend/services/`, so the Vue side gets end-to-end types for free.
- Request validation runs in the app (`config.request_validation = :enabled`).
- CI lints the schema (redocly) and diffs it for breaking changes (oasdiff).

The same schema is what makes a future **React Native** client cheap: point
orval at `swagger/v1/schema.yaml` with a different output target and the
mobile app gets the same typed hooks the SPA has. The contract is the asset;
the SPA is its first consumer, not its only one.

The result: adding a field is one edit in a component class, one line in a
jbuilder view, and the TS type regenerates on `pnpm install`.

## Target architecture

```
Browser
  └── Vue 3 SPA (vue-router, pinia, vue-query, Tailwind 4, VeeValidate+Zod)
        │  app/frontend/frontend/{App.vue,pages,components,stores,composables}
        │  typed client: app/frontend/services/api/ (orval-generated, gitignored)
        ▼
Rails  /api/v1/*   JSON, session-cookie auth (SPA) + JWT (iOS/macOS)
        │  controllers: app/controllers/api/v1/
        │  views:       app/views/api/v1/**.json.jbuilder
        │  contract:    app/api_components/v1/**  →  swagger/v1/schema.yaml
        ▼
Rails  non-API routes that stay server-rendered:
        - PDFs (Grover): invoice/offer/timesheet PDF endpoints
        - mailers
        - /up healthcheck, Sidekiq Web, Flipper UI
        - catch-all → renders the SPA shell layout
```

Everything else — every CRUD screen, the dashboard, settings, the admin
backend — is a Vue route.

### Directory layout (target)

```
app/
├── api_components/
│   ├── params_helper.rb
│   ├── shared/v1/{schemas,parameters,security_schemes}/
│   └── v1/schemas/{customers,projects,timers,invoices,offers,expenses,…}/
├── controllers/api/v1/          # grows from 6 → ~16 controllers
├── views/api/v1/**/*.json.jbuilder
└── frontend/
    ├── entrypoints/{frontend.ts,frontend.scss,tailwind.css}
    ├── frontend/
    │   ├── App.vue
    │   ├── pages/               # one per route
    │   ├── components/
    │   ├── composables/
    │   ├── stores/              # pinia
    │   ├── plugins/{Router,VeeValidate}/
    │   └── types/
    ├── services/
    │   ├── axiosClient.ts       # hand-written mutator
    │   └── api/                 # orval output — generated, gitignored
    ├── shared/
    └── translations/
swagger/v1/schema.yaml           # generated, committed
orval.config.ts
redocly.yaml
```

## Decisions to make before Phase A1

Each has a recommendation; none is settled until you say so.

### D1 — SPA auth: session cookie (recommended) vs JWT

**Recommendation: session cookie for the SPA, JWT kept for future native
clients.**

This works today with no new auth code: `Devise::Strategies::JWT` is already
`unshift`ed onto the default Warden strategy stack
(`config/initializers/devise.rb:9-10`), so `authenticate_user!` in
`Api::BaseController` accepts *either* an `Authorization: Bearer <jwt>` header
or the Devise session cookie.

Cookie wins for the SPA because:

- PDF endpoints (`/invoices/:id/pdf/:pdf`) are plain `<a href>` downloads —
  a token in localStorage can't authenticate those without a blob dance.
- ActionCable (`RunningTimerNotification`) authenticates off the session.
- No token-in-localStorage XSS exposure.

**CSRF posture.** `Api::BaseController` inherits `ActionController::API`,
which does not include `RequestForgeryProtection` — so there is no token
check on API mutations. That is the same choice FleetYards makes: its
`Api::BaseController` has no `protect_from_forgery` either (the
`rescue_from ActionController::InvalidAuthenticityToken` there is dead code),
and `protect_from_forgery` appears only on its HTML controllers. The actual
defense is the **session cookie's `same_site: :lax`**, which stops a
cross-site page from attaching the cookie to a POST/PUT/DELETE.

Reckoning already sets `same_site: :lax`
(`config/initializers/session_store.rb:10`), so the posture is inherited for
free. **Recommendation: match FleetYards — rely on SameSite, don't add token
CSRF to the API.** Two things to confirm rather than assume:

- [ ] No API endpoint mutates state on `GET`. SameSite=Lax *does* send the
      cookie on top-level GET navigation, so a state-changing GET would be
      forgeable. Today's routes are clean here; keep them that way.
- [ ] `Rails.configuration.app.cookie_domain` — if it resolves to a wildcard
      shared across account subdomains, SameSite treats every tenant
      subdomain as same-site. Tenants don't control subdomain content, so
      this is low risk, but it's the one place where the multi-tenant model
      and this decision interact. Verify in A2 alongside D-note in "Risks".

If you want belt-and-braces anyway, the additive version is
`protect_from_forgery with: :exception` on the API base, skipped for
JWT-authenticated requests, with the SPA sending `X-CSRF-Token` from
`<meta name="csrf-token">`. It's ~20 lines and one test. Not recommended by
default — it diverges from the reference implementation for a threat
SameSite already covers.

### D2 — Reshape `/api/v1` in place (recommended) vs additive-only vs `/api/v2`

**Recommendation: reshape `/api/v1` freely.**

The iOS and macOS apps in `/Users/mortik/dev/reckoning/{ios,osx}` were tech
tryouts and never shipped to customers, so v1 has **no consumers to protect**.
That removes the main constraint on this phase: existing payloads can be
normalized rather than accreted onto. Concretely, drop the `links` objects
(`app/views/api/v1/**/_show.json.jbuilder`), which exist for a HATEOAS style
nothing consumes, and fix shapes that only made sense for the Angular
frontend.

Responses are already camelCase (`config/initializers/jbuilder.rb:3` sets
`Jbuilder.key_format camelize: :lower`), which is what the SPA and orval
want — keep that.

**oasdiff still goes in (Phase A1), but non-blocking until the SPA ships.**
It's the wrong gate during a rewrite and the right gate the moment there's a
released client. Flip it to blocking at the end of Phase C.

**Why this pays off later:** a committed OpenAPI schema means a future React
Native app gets a generated, typed orval client from the same
`swagger/v1/schema.yaml` — same generator, different output target. That is
the strategic argument for the contract-first approach beyond the SPA itself,
and it's why the schema is worth maintaining properly rather than
retrofitting docs onto whatever the controllers happen to return.

### D3 — Serializers: jbuilder (recommended) vs alba/blueprinter

**Recommendation: keep jbuilder.** It's already in the Gemfile, already
camelizing, already the pattern in 21 existing API views, and it's exactly
what FleetYards uses alongside `openapi-ruby`. Switching serializer
libraries mid-migration is unrelated risk.

### D4 — `camelize_keys` in the openapi-ruby config

**Recommendation: `config.camelize_keys = false`, write camelCase literally
in the component schemas** — same as FleetYards. Automatic camelization
makes `$ref` names and property names diverge from what you grep for.

### D5 — Pagination shape

**Recommendation: `Link` + `X-Total-*` response headers**, ported from
FleetYards' `app/controllers/concerns/pagination.rb`, on top of the existing
kaminari gem. Keeps list responses as bare arrays (cleaner generated types)
and matches the reference implementation. Declared in the schema as response
headers.

### D6 — Where the SPA is served

**Recommendation: Rails catch-all route** rendering a minimal
`app/views/layouts/spa.html.erb` (vite tags, CSRF meta, locale + env JSON).
No separate static host, no CORS, no CDN config, cookie auth stays
same-origin. The catch-all is added **last** in each porting phase so
un-ported routes keep hitting their ERB controllers.

### D7 — Admin backend (`/backend/*`) in the SPA or left alone?

**Recommendation: port it last, in the same SPA, under a route guard.**
It's 14 views and admin-only. Alternative — leaving it on Bootstrap
forever — blocks the Phase C deletion of Sprockets/Bootstrap, which is
where most of the maintenance win lives.

## API surface inventory

What exists vs what the SPA needs. "Web only" = currently server-rendered
with no API equivalent.

| Domain | Today in `/api/v1` | Needed for SPA |
|---|---|---|
| Sessions | `create`, `destroy` (JWT) | + cookie login, 2FA challenge; JWT path stays for future native clients |
| Registration | web only | `POST /signup` |
| Passwords | web only | request reset, update |
| Current user / 2FA | `users#current` | `GET/PATCH /me`, otp qrcode, backup codes, enable/disable otp |
| Account | web only | `GET/PATCH /account` (settings, plan, tax rates) |
| Customers | index, show, create, destroy | + `update` (web has edit/update, API doesn't) |
| Projects | index, destroy, archive | + show, create, update, unarchive |
| Tasks | index, create (nested + flat) | + update, destroy |
| Timers | index, create, update, destroy, start, stop | + `uninvoiced` |
| Timesheet | — | day / week / month aggregate endpoints |
| Invoices | — | full CRUD + `generate_positions`, `charge`, `pay`, `send_mail`, `send_test_mail` |
| Invoice positions | — | create, update, destroy, reorder |
| Offers | — | full CRUD + state transitions (created → bided → accepted) |
| Offer positions | — | create, update, destroy, reorder |
| Expenses | — | CRUD + `bulk_update`, `bulk_destroy` |
| Expense imports | — | `preview`, `create` |
| Dashboard | — | stats endpoint (`base#index` widgets) |
| Backend / accounts | — | admin CRUD |
| Backend / users | — | admin CRUD + `send_welcome` |
| PDFs | web only | **stays server-rendered** — SPA links to the existing routes |

Roughly **6 existing controllers → ~16**, and ~90 operations to declare.

`app/controllers/templates_controller.rb` and `app/views/templates/`
(7 AngularJS HTML partials) are deleted outright — they exist only to feed
the Angular templateCache.

## Phases

Phases A and B overlap: once the API foundation (A1–A2) is in, each domain's
API work and its SPA page can ship in the same PR pair. Phase C is strictly
last.

### Phase A0 — decisions + spike ✅ done

- [x] Settle D1–D7.
- [x] Spike `openapi-ruby` 4.0.1 on customers end to end: component schemas →
      minitest DSL spec → generated `schema.yaml` → orval client → a Vue page
      consuming it, with a passing Vitest spec.

**Verdict: the round-trip works. No blocker.** Kept rather than thrown away —
the spike code is the first slice of A1/A2.

#### What the spike proved

| Link | Result |
|---|---|
| `rake openapi_ruby:generate` → `swagger/v1/schema.yaml` | Works as shipped; byte-identical on regeneration, so a CI `git diff --exit-code` gate is viable. Runs no tests (findings 1–2) |
| Minitest DSL as the schema source | Works; 11 tests cover customers and replaced the old hand-written controller test |
| `redocly lint` | Valid, 2 warnings (see below) |
| orval → typed vue-query hooks | Works; `useCustomers`/`useCustomer`/`useCreateCustomer`/`useDestroyCustomer` with typed error unions |
| Generated client typechecks | Clean under `tsc --noEmit` |
| Vue page on generated hooks | `CustomersList.vue` + Vitest spec, both green |
| Runtime request validation | Verified live under `:enabled` — a schema-invalid body is rejected before the controller runs (shipped as `:warn_only`, see finding 6) |

#### Findings that change the plan

1. **Generation used to run the whole test suite — fixed upstream, shipped in
   4.0.2.** The generated script `require`s every file matching `PATTERN`, and
   `rails/test_help:11` requires `active_support/testing/autorun`, which calls
   `Minitest.autorun`. Nothing in the gem suppressed it, so any consumer whose
   `test_helper` required `rails/test_help` unguarded ran its whole suite at
   `at_exit`. Measured here: **120 tests ran** during generation, and the rake
   task aborted whenever any unrelated test failed.

   The README had scoped the `schema_generating?` guard to the RSpec↔Minitest
   migration case, which is why this looked like it shouldn't apply to us. That
   scoping was wrong — FleetYards is minitest-only and carries the guard for
   exactly this reason.

   Fixed in [PR #45](https://github.com/openapi-ruby/openapi-ruby/pull/45): the
   script installs an `AutorunSuppressor` before requiring any consumer file.

   **Reckoning needs nothing on its side.** Gemfile requires `">= 4.0.3"`, and
   `rake openapi_ruby:generate` is used as shipped — no `test_helper` guard, no
   custom rake task, no `PATTERN` override. The two local workarounds written
   during the spike have been removed.

   Measured, schema deleted before each run:

   | Gem | Tests run during generation | Schema |
   |---|---|---|
   | 4.0.1 | 120 | written, correct |
   | 4.0.2 | 0 | written, identical |

2. **Generation needs no database** — fixed upstream in
   [PR #47](https://github.com/openapi-ruby/openapi-ruby/pull/47), shipped in
   4.0.3. The document is built purely from declarations, but
   `rails/test_help` calls `maintain_test_schema!` at require time and
   reckoning's `test_helper` adds `ActiveRecord::Migration.check_all_pending!`;
   both opened a connection. The gem stubs both inside the generation
   subprocess only — normal test runs still verify the schema.

   Verified on released 4.0.3 with `DB_PORT=1` against unmodified reckoning:
   succeeds, byte-identical document, zero tests run.

   **The CI `schema-check` job needs only Ruby — no Postgres service.**

3. **`config.schemas[...][:security]` is silently ignored in 4.0.1.**
   `DocumentBuilder#add_security` is never called, so the document always
   emits `security: []` regardless of config — i.e. "no auth required".
   The security *schemes* are emitted as components, which is what
   `no-unused-components` warns about (FleetYards turns the same rule off).
   To describe auth truthfully we must declare `security` per operation in
   the DSL, post-process the YAML, or fix it upstream. **Decide in A1.**

4. **camelCase schema vs snake_case ActiveRecord needs one shared helper.**
   `permitted_params` returns keys exactly as written (camelCase), so it
   can't be handed to `permit` directly. FleetYards solves this ad hoc with
   `params.transform_keys(&:underscore)` scattered across controllers. We
   added `openapi_params(component)` to `Api::BaseController` once — it
   underscores both the incoming keys and the derived permit list.

5. **Two different 400 shapes now exist.** Schema-level rejections come from
   the middleware as `{error, details}`; domain validation failures come from
   the app as `ValidationError` (`{code, message, errors}`). The gem
   auto-attaches a `SchemaValidationError` response to any operation that
   doesn't declare its own 400. Both shapes are real and the SPA's error
   handling must know both. Not worth unifying: the middleware's error
   handler isn't injectable through the engine's initializer.

6. **`request_validation: :enabled` breaks form-encoded posts** to documented
   endpoints — `consumes "application/json"` means a form body reads as
   "Request body is required". The bigger risk is the legacy AngularJS
   frontend, which drives `/api/v1/timers` and `/api/v1/tasks` today: the
   moment those get described, an incomplete description starts rejecting
   real traffic. **Shipped as `:warn_only`; flip to `:enabled` at the end of
   Phase C**, when the SPA is the only client.

7. **Components must be referenced as `::V1::Schemas::…` inside
   `Api::V1`-namespaced tests**, or Ruby resolves `V1::` relative to `Api::`.

8. **Pre-existing frontend debt surfaced.** `@types/node` was missing from
   `package.json` (added), `vue-tsc@3.3.9` crashes against `typescript@5.2.2`,
   and 11 type errors already exist across the islands/entrypoints. The
   `lint:ts` CI gate in A1 can't go green until those are cleaned up — budget
   for it or scope the gate to `app/frontend/services/` first.

#### Cost calibration

Customers — 4 operations, 6 component classes, 11 tests — took well under a
day including learning the gem. The ~90-operation estimate for A3–A8 holds;
per-domain PRs of 2–3 days are the right granularity.

### Phase A1 — OpenAPI foundation (1 PR, ~2 days)

- [ ] `bundle add openapi-ruby -v "~> 4.0"`, `require "openapi_ruby"` in `Rakefile`.
- [ ] `config/initializers/openapi_ruby.rb` — one schema (`v1/schema`),
      `component_paths = ["app/api_components"]`, `camelize_keys = false`,
      `schema_output_format = :yaml`, `schema_output_dir = "swagger"`,
      `request_validation = :enabled`, `response_validation = :disabled`.
- [ ] `test/openapi_helper.rb` requiring `openapi_ruby/minitest`.
- [ ] `pnpm add -D orval @redocly/cli` + `orval.config.ts` targeting
      `swagger/v1/schema.yaml` → `app/frontend/services/api/`,
      `client: "vue-query"`, `httpClient: "axios"`, mutator `axiosClient.ts`.
- [ ] `postinstall: "pnpm generate-api-client"` in `package.json`;
      gitignore the orval output.
- [ ] `redocly.yaml` + `validate-schema` script.
- [ ] CI: `schema-check` job — regenerate schema, fail if the committed
      file differs; `redocly lint`; `oasdiff` against the merge base
      (port `.github/workflows/api-schema-breaking.job.yml`) — reporting
      only, **not** blocking until end of Phase C (D2). Ruby only; the job
      needs no Postgres service (finding 2).

Exit: `rake openapi_ruby:generate` writes a valid `swagger/v1/schema.yaml`
containing the existing customers endpoints; CI green; `pnpm
generate-api-client` produces compiling TS.

### Phase A2 — API conventions layer (1 PR, ~2 days)

- [ ] `Api::BaseController`: add `ActionController::Cookies`, `Pagination`
      concern, consistent `rescue_from` set.
- [ ] Verify the D1 CSRF posture: assert no API route mutates on `GET`, and
      check what `Rails.configuration.app.cookie_domain` resolves to per
      environment. No token CSRF unless that check turns something up.
- [ ] Shared components: `StandardError`, `ValidationError`,
      `PageParameter`, `PerPageParameter`, `SessionCookie` +
      `BearerAuth` security schemes.
- [ ] Port FleetYards' `app/controllers/concerns/pagination.rb` onto kaminari.
- [ ] Backfill the 6 existing controllers with components + DSL specs so v1
      is fully described before it grows.

Exit: schema describes 100% of today's v1; the two CSRF checks above are
answered in writing.

### Phase A3–A8 — API buildout, one domain per PR pair

Order chosen so each SPA page can land right behind its API. Each PR:
components → controller actions → jbuilder views → minitest DSL spec →
regenerated schema → regenerated client.

- [ ] **A3** Auth + me + account — sessions (cookie), signup, password reset,
      2FA, `GET/PATCH /me`, `GET/PATCH /account`.
- [ ] **A4** Customers (add `update`) + Projects (add show/create/update/
      unarchive) + Tasks (add update/destroy).
- [ ] **A5** Timers + timesheet aggregates (day/week/month) + `uninvoiced`.
- [ ] **A6** Invoices + invoice positions + the action endpoints
      (`generate_positions`, `charge`, `pay`, `send_mail`, `send_test_mail`).
- [ ] **A7** Offers + offer positions + state transitions.
- [ ] **A8** Expenses + expense imports + dashboard stats + backend admin
      (accounts, users, `send_welcome`).

Exit per PR: new operations in `schema.yaml`, integration tests green,
oasdiff reports additive-only.

### Phase B1 — SPA shell (1 PR, ~3 days)

- [ ] `pnpm add vue-router pinia pinia-plugin-persistedstate @tanstack/vue-query axios qs vee-validate zod`
- [ ] `app/frontend/entrypoints/frontend.ts` — createApp + router + pinia +
      VueQueryPlugin (mirrors FleetYards' entrypoint).
- [ ] `app/frontend/services/axiosClient.ts` — `withCredentials: true`,
      `qs` param serializer, `X-CSRF-Token` header, 401 → redirect to login.
- [ ] `App.vue` + app shell (nav, account switcher, flash/toast host) in
      Tailwind, no Bootstrap classes.
- [ ] `plugins/Router` with a `requiresAuth` guard reading a pinia
      `useCurrentUserStore` hydrated from `GET /api/v1/me`.
- [ ] `app/views/layouts/spa.html.erb` + a `SpaController#index`, mounted at
      **one** throwaway route (`/app`) — no catch-all yet.
- [ ] i18n: move `config/locales` strings the frontend needs into
      `app/frontend/translations/` (vue-i18n), independent of i18n-js.

Exit: `/app` renders an authenticated shell with a working login → dashboard
skeleton → logout round-trip, against the real API.

### Phase B2–B8 — page ports, one domain per PR

Same order as A3–A8, each landing immediately after its API PR. Per page:
Vue page + components, vue-query hooks from the generated client, VeeValidate
+ Zod for forms, Vitest specs for logic-bearing components, Playwright spec
for the flow, then **the Rails route is repointed at the SPA and the old ERB
views + Angular/jQuery/Coffee for that screen are deleted in the same PR**.

- [ ] **B2** Login / signup / password reset / 2FA.
- [ ] **B3** Customers list + form; Projects list, detail, form; Tasks.
- [ ] **B4** Timesheet (day/week/month) — reuses `app/frontend/islands/timesheet/`
      SFCs, promoted to `frontend/pages/timesheet/`; deletes
      `app/assets/javascripts/angular/timesheet/`.
- [ ] **B5** Timers calendar — reuses `islands/timers-calendar/`; deletes
      `angular/timers_calendar/`.
- [ ] **B6** Invoices list + detail + **line-item editor** (the other
      genuinely complex screen); PDF links point at the existing Rails routes.
- [ ] **B7** Offers list + detail + line-item editor + state transitions.
- [ ] **B8** Expenses + expense import wizard + dashboard + settings tabs +
      backend admin.

Exit per PR: the ported screen has no server-rendered ERB left, Playwright
covers it, and the corresponding legacy JS is gone from the repo.

### Phase C — legacy removal (multi-PR, ~1 week)

Only once B8 has landed and stabilized.

- [ ] Catch-all route → SPA shell; delete `SpaController`'s `/app` stub.
- [ ] Delete `app/assets/javascripts/`, `app/assets/stylesheets/`,
      `app/views/templates/`, `TemplatesController`, `vendor/` bower bundles.
- [ ] Delete `app/frontend/controllers/*_controller.ts` (Stimulus) and
      `app/frontend/lib/mount-islands.ts`.
- [ ] Drop gems: `bower-rails`, `bootstrap-sass`, `bourbon`, `sass-rails`,
      `coffee-rails`, `jquery-rails`, `uglifier`, `sprockets-rails`,
      `turbo-rails`, `i18n-js`.
- [ ] Remove `@hotwired/turbo`, `@hotwired/stimulus` from `package.json`.
- [ ] Turn Tailwind **preflight on**; sweep the remaining Bootstrap class
      names (`btn-default`, `col-md-*`, `panel-*`, `glyphicon`).
- [ ] Delete every remaining `app/views/**` except layouts, mailers, api
      jbuilder views, and the PDF templates.
- [ ] Update `AGENTS.md` — the whole "Frontend modernization in flight"
      section is now history.

Exit: `rg 'angular|jquery|coffee|bootstrap'` over `app/` returns nothing but
PDF-template hits.

## Testing strategy

| Layer | Tool | Notes |
|---|---|---|
| API contract | minitest + `OpenapiRuby::Adapters::Minitest::DSL` | The spec **is** the schema; an untested endpoint isn't documented |
| API behavior | existing minitest integration tests | Keep `test/integration/` conventions |
| Schema drift | CI `schema-check` job | Regenerate + `git diff --exit-code` |
| Breaking changes | oasdiff vs merge base | Reporting-only during the rewrite; blocking from end of Phase C |
| Vue units | Vitest + `@vue/test-utils` (already installed) | Composables and logic-bearing components |
| E2E | Playwright (already installed) | Rewritten per screen during B2–B8; `DB_PORT=8241` locally, port 8250 |
| Types | `vue-tsc --noEmit` + `tsc --noEmit` | Generated client makes API drift a type error |

Add to `package.json`: `lint:ts`, `vue-tsc`, `generate-api-client`,
`validate-schema` (copy FleetYards' script block).

## Risks

| Risk | Mitigation |
|---|---|
| CSRF on cookie-auth'd API mutations | `same_site: :lax` already set on the session cookie; A2 verifies no mutating `GET` and checks the cookie domain across tenant subdomains (D1) |
| Reshaping v1 with no compatibility net | Acceptable — no released client. oasdiff runs from A1 as a reporting signal and becomes blocking at end of Phase C, before any native client exists |
| ~90 operations is a lot of hand-written DSL | One domain per PR; A0 spike calibrates the real per-endpoint cost before committing |
| Half-migrated app: some routes SPA, some ERB, two navs | Port in whole domains; catch-all lands only in Phase C; accept a nav that full-page-loads between old and new for the duration |
| Multi-tenancy (`current_account` via subdomain) interacting with cookie auth | Cover in A3 — session cookie must be scoped so subdomain accounts still resolve |
| Losing the 2FA / Devise edge cases in a hand-rolled SPA login | B2 gets Playwright coverage for otp-required, backup codes, lockout before the ERB login is deleted |
| Sunk Hotwire work creates "why did we build that" churn | Stated explicitly at the top of this doc; decision is recorded, not rediscovered |
| Timesheet/invoice-editor parity regressions (the two hard screens) | They ship late (B4, B6) against a stable API; existing island SFCs already encode the behavior |

## Rollback

- **Phases A1–A8** are additive to the API. Revert the PR; nothing that
  shipped depended on it yet.
- **Phases B2–B8** each delete the ERB screen they replace. Revert-the-PR
  restores it — but only cleanly if the PR is reverted before later PRs
  build on it. Keep them small and merge them in order.
- **Phase C** is the one-way door. Tag the commit before the Sprockets
  deletion PR.
- No feature flags: route-level cutover per domain is the flag. A screen is
  either SPA or ERB, never both.

## Estimates

Part-time, alongside feature work.

| Phase | Estimate |
|---|---|
| A0 — decisions + spike | 1 day |
| A1 — OpenAPI foundation | 2 days |
| A2 — conventions + CSRF + pagination | 2 days |
| A3–A8 — API buildout (6 domains) | 2–3 days each → ~2.5 weeks |
| B1 — SPA shell | 3 days |
| B2–B8 — page ports (7 domains) | 3–5 days each → ~4 weeks (B4/B6/B7 are the heavy ones) |
| C — legacy removal | 1 week |

Calendar: **~3 months part-time, ~7–8 weeks focused.** Comparable to the
Hotwire plan's remaining scope, but ends with a typed, tested contract that
any future client — React Native included — generates against instead of
reverse-engineering.

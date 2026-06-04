# Frontend migration plan

Exec plan for moving Reckoning's frontend off the legacy stack
(Sprockets + AngularJS + jQuery + CoffeeScript + Bootstrap 3 +
haml + slim) onto a Rails-native modern stack: **Vite + Hotwire +
Stimulus + Tailwind + HERB-flavored ERB**, with **Vue 3 islands** on
the two screens that genuinely need them.

## Why this shape

Reckoning is a CRUD app — customers, projects, invoices, offers,
settings. The server already owns the truth; most screens are forms
and lists. **Hotwire (Turbo + Stimulus) was designed for exactly this
case**: keep server-rendered HTML, layer interactivity on top.

There are two surfaces that are genuinely state-heavy — the
**timesheet calendar** (drag-drop, day/week/month views) and the
**invoice/offer line-item editor** (repeatable rows, live totals).
Those get **Vue 3 islands**: a single Vue app mounted on one
element, not a whole-app SPA.

Net result: ~80% of the frontend is server-rendered HTML with
sprinkles; ~20% is Vue. Same shape as the existing app, modernized.

## Why HERB instead of straight ERB or sticking with haml/slim

The repo today uses **both** haml (65 templates) and slim (69
templates) — two engines for the same job. We collapse to one.

- **HERB** (https://github.com/marcoroth/herb) is a modern HTML+ERB
  compiler. Syntactically ERB-compatible, but parses HTML structure
  so it catches unclosed tags / attribute typos at compile time.
  Has lint + LSP + editor integration. Designed with Hotwire-style
  Rails apps in mind.
- **Plain ERB** would also work. Picking HERB buys us the tooling
  for free, and the migration target is "valid ERB" either way —
  HERB *is* ERB.
- haml/slim's indentation-based syntax adds cognitive load when
  you're also tracking Turbo Frame / Stimulus data attributes
  nested in conditionals. ERB's tag-mirrors-HTML form is friendlier
  for the Hotwire phase.

## Goals

1. **Vite** drives the bundle pipeline (HMR in dev, code-splitting in prod).
2. **TypeScript** across all new JS/TS.
3. **Tailwind 4** in place of Bootstrap 3.
4. **HERB-flavored ERB** is the single template language. haml + slim both gone.
5. **Hotwire (Turbo + Stimulus)** is the default interactive layer.
6. **Vue 3 islands** only on the two screens that need them.
7. **Playwright** for e2e, replacing Cypress 12.
8. AngularJS, CoffeeScript, Sprockets, bower-rails, jquery-rails, turbolinks all gone.

## Non-goals

- Rewriting business logic. Controllers, models, jobs, PDF rendering (Grover) stay.
- API-first / SPA-style design. The server keeps rendering HTML for the main app.
- Native mobile. PWA-ready bundle is fine; a native shell isn't.

## Target stack

| Concern | Target | Why |
|---|---|---|
| Bundler | Vite (`vite_rails`) | HMR, code-splitting, Rails 8 default |
| Templates | HERB-flavored ERB | Single engine, compile-time HTML checks |
| Routing | Server-side Rails + Turbo Drive | Reuses existing routes; SPA-like nav |
| Frame swaps | `<turbo-frame>` | Partial updates without writing JS |
| Async pushes | `<turbo-stream>` over ActionCable | Realtime list updates, flash notifications |
| Behaviors | Stimulus controllers | Scoped JS via `data-controller` |
| Heavy screens | Vue 3 + `<script setup lang="ts">` | Mounted as islands on 2 screens only |
| Styling | Tailwind 4 via `@tailwindcss/vite` | Utility-first, gradual adoption |
| Forms | Rails `form_with` + Turbo | No form library for 95% of cases |
| Heavy forms | VeeValidate + Zod (inside Vue islands only) | When Rails forms aren't enough |
| Tests | Vitest (Vue islands), Playwright (e2e) | |
| Lint | ESLint + Prettier + HERB lint | |

## Phased delivery

Each phase is one or a short series of PRs. Phases run **strictly in
order** — earlier phases ship and stabilize before the next starts.
The legacy stack runs alongside the new throughout. Deletion only
happens after the modern equivalent is proven.

### Phase 0 — inventory (optional, ~half day)

Goal: a written map of every JS entrypoint and template, so any
later regression is provably ours.

- [ ] `docs/frontend-inventory.md` listing every `//= require`,
      every AngularJS controller, every haml/slim template path.

### Phase 1 — install Vite alongside Sprockets (1 PR, ~1 day)

Goal: Vite builds an empty entrypoint into `public/vite/`. Sprockets
still serves the live app. Zero behavior change.

- [ ] `bundle add vite_rails`
- [ ] `bundle exec vite install` — generates `vite.config.ts`,
      `app/frontend/entrypoints/application.{ts,scss}`, `bin/vite`,
      `Procfile.dev` integration.
- [ ] Update `Dockerfile` to copy `app/frontend/`, install pnpm deps,
      run `bin/vite build` in the build stage.
- [ ] Add `<%= vite_client_tag %>` to a **new** layout
      `application_v2.html.erb` — old layout untouched.

Exit: `bin/vite build` writes `public/vite/.vite/manifest.json`,
Docker image still builds, CI green.

### Phase 2 — Tailwind alongside Bootstrap (1 PR, ~1 day)

- [ ] `pnpm add -D tailwindcss @tailwindcss/vite`
- [ ] Wire `tailwindcss()` into `vite.config.ts`.
- [ ] `app/frontend/entrypoints/tailwind.css` with `@import "tailwindcss";`.
- [ ] `<%= vite_stylesheet_tag 'tailwind.css' %>` in `application_v2.html.erb`.
- [ ] Probe page (`/backend/users`) gets Tailwind utilities — visually verify.

Exit: a Tailwind utility renders correctly on the probe page; every
other screen still Bootstrap 3.

### Phase 3 — HERB tooling + haml/slim → ERB conversion (multi-PR, ~3–5 days)

Goal: every template is plain ERB with HERB tooling validating
structure. Two template engines collapse to one.

- [ ] Add HERB tooling (`@herb-tools/cli` and/or the gem variant —
      decide when phase starts).
- [ ] Wire `herb lint` into CI as a new job (`herb-lint`).
- [ ] Convert templates in batches of ~10, by domain area:
  - [ ] `app/views/devise/`
  - [ ] `app/views/accounts/`
  - [ ] `app/views/customers/`
  - [ ] `app/views/projects/`
  - [ ] `app/views/invoices/`
  - [ ] `app/views/offers/`
  - [ ] `app/views/timesheet/`
  - [ ] `app/views/current_user/`
  - [ ] `app/views/backend/`
  - [ ] `app/views/layouts/`
  - [ ] `app/views/shared/` and remaining partials
- [ ] Tooling: `haml2erb` and `slim2erb` (or hand-converted in small
      batches — both formats translate mechanically).
- [ ] Run the e2e suite + click through each migrated section
      manually before merging that batch's PR.
- [ ] After every batch lands and stabilizes: drop `gem "haml-rails"`,
      `gem "haml"`, `gem "slim-rails"`.

Exit: 0 `.haml` files, 0 `.slim` files, every template parses under HERB.

### Phase 4 — Hotwire baseline (1 PR, ~2 days)

Goal: Turbo Drive + Stimulus loaded on every page, replacing
Turbolinks and the bulk of jQuery sprinkles.

- [ ] `pnpm add @hotwired/turbo-rails @hotwired/stimulus`
- [ ] `app/frontend/entrypoints/application.ts` imports turbo-rails
      and starts Stimulus with a vite-glob controller registry.
- [ ] Drop `gem "turbolinks"` and the `//= require turbolinks`.
- [ ] Verify Devise sign-in/sign-out under Turbo Drive (Devise 5 is
      Turbo-aware; logout links may need `data-turbo-method="delete"`).
- [ ] Convert the simplest legacy jQuery init (`app.coffee`'s tab
      handler) to `tabs_controller.ts` as the first real Stimulus
      controller.

Exit: every page loads through Turbo Drive; one Stimulus controller
actively in use.

### Phase 5 — Turbo Frames on CRUD screens (multi-PR, ~1 week)

Goal: high-traffic CRUD screens use `<turbo-frame>` for partial
updates instead of full reloads. Each screen is its own small PR.

Lowest-risk-first order:

1. **Customer list/detail** — Turbo Frame pagination + edit-in-place.
2. **Project list/detail** — same pattern.
3. **Offer list** — Turbo Stream for inline state changes
   (created → bided → accepted).
4. **Invoice list** — Turbo Frame around the filter form + result table.
5. **Settings tabs** — Turbo Frame per tab section.
6. **Dashboard** — Turbo Frame around each widget; Stimulus for chart init.

Each PR adds `<turbo-frame id="...">` wrappers, swaps the controller
to render the partial inside the frame on XHR, ships Stimulus
controllers for any remaining JS. Existing AngularJS/jQuery on
these screens gets deleted in the same PR.

Exit: every CRUD screen renders without AngularJS / jQuery.

### Phase 6 — Vue 3 islands for the two complex screens (~2 weeks per island)

The two screens that justify Vue's complexity:

1. **Timesheet** (`app/views/timesheet/`, current AngularJS in
   `app/assets/javascripts/angular/timers_calendar/` and
   `timesheet/`) — drag-drop calendar, day/week/month views,
   autosave, keyboard nav.
2. **Invoice/Offer line-item editor** — repeatable nested rows, live
   totals, currency math, drag-reorder.

Per island:

- [ ] `app/frontend/islands/<name>/` with a Vue 3 SFC + types.
- [ ] `app/frontend/entrypoints/<name>.ts` mounts onto a designated
      `<div data-island="...">`.
- [ ] The Rails view renders the mount-point + Vite tag for the entrypoint.
- [ ] Tailwind classes on the Vue side (no duplicate styling layer).
- [ ] Feature flag via env var (`NEW_TIMESHEET=1`, `NEW_LINE_ITEMS=1`).
- [ ] Vitest specs for the island's components.
- [ ] Playwright spec for the screen end-to-end.

Exit per island: parity with the AngularJS original, validated
against staging behind the flag for at least a week, then flag
flipped to default-on.

### Phase 7 — drop AngularJS (1 PR, ~half day)

After both Vue islands are default-on:

- [ ] Delete `app/assets/javascripts/angular/`.
- [ ] Delete `//= require ./angular/init` + `//= require_tree ./angular`.
- [ ] Delete `vendor/` Bower-managed Angular bundles.
- [ ] Drop `gem "bower-rails"`.

### Phase 8 — Cypress → Playwright (1 PR, ~1 day)

- [ ] `pnpm add -D @playwright/test`
- [ ] `playwright.config.ts` with sharding configured for CI.
- [ ] Port existing Cypress specs to Playwright syntax
      (`cy.` → `await page.`).
- [ ] Update `.github/workflows/e2e-tests.job.yml` to use the
      `mcr.microsoft.com/playwright` image and run `pnpm test:e2e`.
- [ ] Delete `cypress/`, `cypress.config.ts`, the cypress package.json
      entries, the cypress GH Actions step.

### Phase 9 — drop Bootstrap 3 + Sprockets (1 PR per cleanup, ~1 week of grunt work)

After every screen has been migrated:

- [ ] Grep-verify zero references to Bootstrap 3 classes
      (`btn-default`, `col-md-*`, `panel-*`, `glyphicon`, etc.).
- [ ] Drop `gem "bootstrap-sass"`, `gem "bourbon"`, `gem "sass-rails"`,
      `gem "coffee-rails"`, `gem "jquery-rails"`, `gem "uglifier"`.
- [ ] Delete `app/assets/javascripts/` and `app/assets/stylesheets/`.
- [ ] Promote `application_v2.html.erb` to `application.html.erb`.

### Phase 10 — i18n-js 3 → 4 (1 PR, ~half day)

v3 ships a Rack middleware that writes a global JS object; v4 ships
per-locale chunks loaded via the Vite manifest.

- [ ] `bundle update i18n-js` to v4.
- [ ] Drop `config.middleware.use I18n::JS::Middleware`.
- [ ] Replace the legacy `i18n` JS reads with the v4 import pattern.

## Risk areas + mitigations

| Risk | Mitigation |
|---|---|
| haml/slim → ERB conversion subtly changes whitespace and breaks layout | Phase 3 batches stay small (~10 templates) and ship one PR each; e2e + click-through before merge |
| Turbo Drive double-submit on Devise forms | Test sign-in / sign-up / password reset flows explicitly in Phase 4 |
| Stimulus event listeners stack across Turbo navigation | Use `connect()` / `disconnect()` properly; document the pattern in `AGENTS.md` |
| Vue island can't read Rails-rendered locale data | Pass it through `data-` attributes on the mount point, parsed in the island's setup() |
| Tailwind classes don't visually match Bootstrap 3 layouts | Probe page in Phase 2 catches macro issues; per-screen migration catches micro issues before merge |
| Two test paradigms (server-rendered + Vue) get hard to maintain | Server-rendered: Playwright. Vue islands: Vitest + Playwright. Same Playwright config covers both. |
| AGENTS.md drifts from reality as phases land | Update AGENTS.md's "Frontend modernization in flight" section at the end of each phase |

## Rollback strategy

- **Per-PR revert** is the default. Each phase is one PR (or a short
  series); revert via the GitHub UI returns to the prior known-good
  state.
- **Phase 6 (Vue islands)**: feature flag flip. Env var off → Rails
  serves the legacy AngularJS view.
- **Phase 9 (Sprockets deletion)** is the only one-way door. Tag the
  commit before merging so we can `git checkout` it if a problem
  manifests only under prod load.

## Time estimates

Part-time, alongside day-to-day feature work:

| Phase | Estimate |
|---|---|
| 0 — inventory | 0.5 day (optional) |
| 1 — install Vite | 1 day |
| 2 — Tailwind alongside | 1 day |
| 3 — haml/slim → ERB | 3–5 days (batched) |
| 4 — Hotwire baseline | 2 days |
| 5 — Turbo Frames on CRUD | 1 week (parallelizable) |
| 6 — Vue islands | 2 weeks × 2 = 4 weeks |
| 7 — drop AngularJS | 0.5 day |
| 8 — Cypress → Playwright | 1 day |
| 9 — drop Bootstrap + Sprockets | 1 week |
| 10 — i18n-js v4 | 0.5 day |

Calendar: ~2–3 months part-time, ~6 weeks focused.

## When this plan starts

After all in-flight infra PRs settle:

- #852 (release-please) — merged ✓
- #853 (Kamal) — merged ✓; live deploy verified
- #855 (Brakeman cleanup) — merged ✓
- #856 (AGENTS.md) — merged ✓
- Capistrano removed (the post-Kamal cleanup PR — pending)

These should land and stabilize before the frontend rewrite begins so
the two workstreams don't have to coordinate mid-flight.

# Frontend migration plan

Exec-plan for moving Reckoning's frontend off the legacy Sprockets +
AngularJS + Bootstrap 3 + CoffeeScript stack onto the modern stack
fleetyards already runs in production.

## Why now

The P0 hardening series (Ruby 3.4, Rails 7.2, PG 17, Redis 7, CVE
sweep, container deploy) settled the backend. The frontend is the
last legacy surface — it's the largest remaining tech-debt block and
the source of every "the JS won't minify" CI break.

## Goals

1. Vite-driven build pipeline with HMR in dev and code-splitting in prod.
2. TypeScript across all new JS/TS.
3. Tailwind 4 in place of Bootstrap 3.
4. Stimulus or Vue 3 for interactive behavior (no AngularJS).
5. Playwright for e2e (replaces Cypress 12).
6. All `*.coffee` removed, all `*.haml`/`*.slim` either kept as
   server-rendered or replaced by Vue components, never both at once
   for a given screen.
7. CI builds and ships the Sprockets-free image.

## Non-goals

- Rewriting business logic. Server-side controllers, models, jobs,
  and PDF rendering (Grover) stay as-is.
- Migrating away from haml/slim wholesale. Server-rendered views stay
  server-rendered until a specific screen gets a Vue rewrite.
- Native mobile. PWA is in scope (fleetyards ships it via
  `vite-plugin-pwa`); a Capacitor / native shell is not.

## Target stack (mirrors fleetyards)

| Concern | Target |
|---|---|
| Bundler | Vite (`vite_rails`) |
| Framework | Stimulus for simple sprinkles; Vue 3 + `<script setup lang="ts">` for component-heavy screens |
| Types | TypeScript, `vue-tsc` for `.vue` files |
| Styling | Tailwind 4 via `@tailwindcss/vite` |
| Component lib | Headless UI primitives (Floating UI / Reka UI / hand-rolled — TBD per need) |
| Forms | VeeValidate v4 + zod schemas (matches fleetyards) |
| HTTP | `axios` (or `fetch` directly); `@tanstack/vue-query` for caching |
| Lint | ESLint flat config + Prettier |
| Tests | Vitest for unit, Playwright for e2e |
| API client | Hand-written for now; OpenAPI + Orval is a separate workstream |

## Phased delivery

Each phase is one or a small number of PRs. Phases run **strictly in
order** — earlier phases land and stabilize before the next starts.
Vite runs **alongside** Sprockets the entire migration; we delete
Sprockets only after every entrypoint has moved.

### Phase 0 — pin the existing stack (one PR, ~half day)

Goal: prove the legacy stack still builds and ships, so any regression
in later phases is provably mine.

- [ ] Snapshot a known-good `public/assets/` build into the Docker
      image's test stage. (Optional — only if asset bugs are common.)
- [ ] Document the current `application.js` manifest and the AngularJS
      entry points so we know what surface area we're moving.

Output: a short note in `docs/frontend-current-state.md` mapping every
`//= require` to its current behavior.

### Phase 1 — install Vite, keep Sprockets (one PR, ~1 day)

Goal: get Vite building a single empty entrypoint into `public/vite/`,
served alongside the existing Sprockets pipeline. Zero behavior change.

- [ ] `bundle add vite_rails`
- [ ] `bundle exec vite install` — generates `vite.config.ts`,
      `app/frontend/entrypoints/application.{ts,scss}`, the
      `bin/vite` shim, `Procfile.dev` update.
- [ ] Add `@vitejs/plugin-vue` and `unplugin-vue-components` to
      package.json (don't use them yet, but bundle them so the next
      phase doesn't pull a flood of new deps).
- [ ] Add `<%= vite_client_tag %>` and `<%= vite_typescript_tag 'application' %>`
      to a NEW layout (`application_v2.html.erb`) — don't touch the
      existing layout yet.
- [ ] Update `Dockerfile` to copy `app/frontend/`, install pnpm
      production deps, and run `bin/vite build` in the build stage.
- [ ] Verify CI's `e2e-tests` still passes (it should — nothing
      changed in the rendered output).

Exit criteria: `bin/vite build` produces a manifest in
`public/vite/.vite/manifest.json`, the image builds, and
`application_v2.html.erb` (if rendered manually) loads the Vite
client without console errors.

### Phase 2 — Tailwind alongside Bootstrap (one PR, ~1 day)

Goal: Tailwind utilities available in templates without removing
Bootstrap. Both stylesheets compile, both ship.

- [ ] `pnpm add -D tailwindcss @tailwindcss/vite`
- [ ] Wire `tailwindcss()` into `vite.config.ts`.
- [ ] Create `app/frontend/entrypoints/tailwind.css` with just
      `@import "tailwindcss";`.
- [ ] Add `<%= vite_stylesheet_tag 'tailwind.css' %>` to
      `application_v2.html.erb` (only).
- [ ] Add a "Tailwind probe" component on one low-traffic admin page
      (e.g. `/backend/users`) using only Tailwind classes — visually
      verify rendering matches expected.

Exit criteria: a tailwind utility (`text-red-500`) renders red on the
probe page; Bootstrap layouts elsewhere are unchanged.

### Phase 3 — Stimulus for the simplest interactive bits (one PR, ~2 days)

Goal: replace jQuery-driven small interactions (tab toggles, dropdown
opens, ladda buttons, noty notifications) with Stimulus. Vue stays out
until we have a real reason.

- [ ] `pnpm add @hotwired/stimulus`
- [ ] Create `app/frontend/controllers/` with one example controller
      (e.g. `tabs_controller.ts`).
- [ ] Migrate the simplest existing jQuery usage (likely
      `app.coffee`'s tab init) to Stimulus.
- [ ] Update the **single screen** that uses the new layout to drop
      the jQuery init.

Exit criteria: a Stimulus controller works on at least one screen,
shipped through the Vite pipeline, while every other screen still
runs the legacy jQuery.

### Phase 4 — Vue 3 + the first real screen (one PR per screen, repeat)

Goal: pick one AngularJS-heavy screen, rewrite it as a Vue 3 SFC, ship
behind a feature flag.

The picks, in order of "easiest to validate":

1. The **dashboard widgets** (charts + counters) — read-only, no form
   complexity.
2. **Timesheet calendar** (`app/assets/javascripts/angular/timers_calendar/`)
   — Angular today; a major Vue rewrite candidate.
3. **Timesheet day/week view** (Angular).
4. **Invoice form** (line items, totals) — the highest-traffic form,
   touch last.
5. **Offer form** — like invoice form.

For each screen:

- [ ] Build a `.vue` component under
      `app/frontend/components/<screen-name>/`.
- [ ] Mount via `createApp(...).mount('#app-<screen>')` in
      `app/frontend/entrypoints/<screen>.ts`.
- [ ] The Rails view renders the mount-point `<div>` and the Vite tag
      for that entrypoint.
- [ ] Feature flag via env var (e.g. `NEW_TIMESHEET=1`) so we can
      A/B compare in production briefly before flipping the default.

Exit criteria per screen: visual + functional parity with the
AngularJS original, validated by hand against staging.

### Phase 5 — drop AngularJS (one PR, ~half day after Phase 4 completes for every Angular screen)

Goal: every Angular usage has a Vue equivalent. Time to delete.

- [ ] Remove `app/assets/javascripts/angular/` and the manifest
      `//= require ./angular/init` / `//= require_tree ./angular`.
- [ ] Drop the legacy `bower_components/angular*` packages.
- [ ] Drop the legacy `gem "bower-rails"`.

### Phase 6 — Playwright for e2e (one PR, ~1 day)

Goal: Cypress 12 → Playwright. fleetyards uses the official
`mcr.microsoft.com/playwright` container in CI.

- [ ] `pnpm add -D @playwright/test`
- [ ] Create `playwright.config.ts` (use fleetyards' as the template).
- [ ] Port the few existing Cypress specs to Playwright syntax (search
      `cy.` → `await page.`).
- [ ] Update `.github/workflows/e2e-tests.job.yml` to use the
      Playwright container image and run `pnpm test:e2e`.
- [ ] Delete `cypress/`, `cypress.config.ts`, the cypress gems.

### Phase 7 — drop Bootstrap 3, drop Sprockets (one PR, ~1 week of grunt work)

Goal: every screen now styled with Tailwind. Time to delete the
legacy stylesheet pipeline.

- [ ] Verify no template still references a Bootstrap 3 class — grep
      for `.btn-default`, `.col-md-*`, `.panel-*`, etc.
- [ ] Drop `gem "bootstrap-sass"`, `gem "bourbon"`, `gem "sass-rails"`,
      `gem "coffee-rails"`, `gem "jquery-rails"`, `gem "turbolinks"`,
      `gem "uglifier"` (already replaced by `terser`).
- [ ] Drop `app/assets/javascripts/` and `app/assets/stylesheets/`.
- [ ] Drop the `application_v2.html.erb` shim — promote it to
      `application.html.erb`.
- [ ] Drop `//= require turbolinks` and `data-turbolinks-*` attributes.

### Phase 8 — i18n-js 3 → 4, drop the v3 middleware

Coupled with the asset migration because `i18n-js` v3 ships a Rack
middleware that writes a global JS object; v4 ships per-locale chunks
loaded via the Vite manifest.

- [ ] `bundle update i18n-js` to v4.
- [ ] Drop `config.middleware.use I18n::JS::Middleware` from
      `config/application.rb`.
- [ ] Replace the legacy `i18n` JS reads with the v4 import pattern.

## Risk areas + mitigations

| Risk | Mitigation |
|---|---|
| Big-bang migrations break invoices for live customers | Every phase ships behind a flag, A/B'd on a staging mirror first. The Capistrano deploy is still the source of truth until Kamal cutover completes. |
| Tailwind classes don't visually match Bootstrap 3 layouts | Phase 2 ships one probe page; visually compare side-by-side before continuing. |
| Vue rewrites lose Angular's two-way binding subtleties (typing-while-saving, dirty checks) | Each Vue screen needs its own e2e spec covering keyboard input, debounce, autosave. |
| Vite + Rails asset_host / CDN config | Mirror fleetyards' `VITE_RUBY_ASSET_HOST` build arg. |
| Test parallelization regresses | Knapsack-sharded minitest stays; Vitest runs in parallel; Playwright shards in CI like fleetyards does. |
| AGENTS.md drift | Update AGENTS.md "Frontend modernization in flight" section as each phase lands. |

## Rollback strategy

- Each phase is one PR (or a short series). Revert PR via the GitHub
  UI takes the codebase to the prior known-good state.
- For Phase 4+ (per-screen Vue rewrites), the feature flag is the
  rollback — set it to off in env, Rails serves the legacy template.
- For Phase 7 (Sprockets deletion) — irreversible without a revert.
  Tag the commit before merging so we can `git checkout` it if a
  problem only manifests in prod under load.

## Time estimates

These assume one engineer working on this part-time alongside
day-to-day feature work.

| Phase | Estimate | Notes |
|---|---|---|
| 0 — pin current state | 0.5 day | optional |
| 1 — install Vite | 1 day | |
| 2 — Tailwind alongside | 1 day | |
| 3 — Stimulus | 2 days | |
| 4 — Vue screens | 1-2 weeks per screen | × ~5 screens |
| 5 — drop AngularJS | 0.5 day | |
| 6 — Playwright | 1 day | |
| 7 — drop Bootstrap + Sprockets | 1 week | |
| 8 — i18n-js v4 | 0.5 day | |

Calendar: ~2-3 months at part-time. Compressed to ~6 weeks if focused.

## When this plan starts

After:
- #852 (release-please) merged
- #853 (Kamal) merged and live deploy verified
- #855 (Brakeman cleanup) merged
- #856 (AGENTS.md) merged
- Capistrano removed (the post-Kamal cleanup PR)

These are infrastructure pieces that the frontend work shouldn't have
to coordinate with mid-flight.

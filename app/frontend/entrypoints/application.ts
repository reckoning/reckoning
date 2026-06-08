// Vite entrypoint — modern asset pipeline lives here.
//
// Loaded on every page via `<%= vite_typescript_tag "application" %>`
// in app/views/layouts/_head.html.erb alongside the legacy Sprockets
// bundle.
//
// Phase 4b of the frontend migration:
// - Turbo Drive owns page navigation. The Turbolinks gem has been
//   dropped from the Sprockets bundle.
// - Stimulus controllers under app/frontend/controllers/ auto-register
//   by filename (e.g. `tabs_controller.ts` → `data-controller="tabs"`).
// - A `turbo:load → turbolinks:load` shim re-fires the legacy event
//   so the 20+ `document.addEventListener("turbolinks:load", …)`
//   callsites in app/assets/javascripts/ keep working under Turbo.

import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"

import { configureAccounting, installAccountingGlobal } from "../lib/accounting"
import { configureMomentLocale } from "../lib/moment-locale"
import { mountIslands } from "../lib/mount-islands"
import Hello from "../islands/hello/Hello.vue"
import TimersCalendar from "../islands/timers-calendar/TimersCalendar.vue"

// PDF.js v4+ ships ESM-only. Lazy-loaded so the 1.5 MB pdfjs core +
// worker don't ship on pages that never render a PDF (most of them).
// Triggered by `dispatchEvent(new CustomEvent("pdfjs:request"))` —
// the legacy `app/pdf_viewer.coffee` fires this when it sees
// `.pdf-viewer` mount points. After load, `window.pdfjsLib` is set
// and a `pdfjs:ready` event fires so callers can start rendering.
//
// Replaces the v3.x Sprockets-loaded `//= require pdfjs-dist/build/pdf`
// + UMD `window.pdfjsLib` global. Bumping to v4 closes 13 high-severity
// transitive vulns (canvas → node-pre-gyp → tar/minimatch/etc.).
let pdfjsLoad: Promise<unknown> | null = null
document.addEventListener("pdfjs:request", async () => {
  if (!pdfjsLoad) {
    pdfjsLoad = (async () => {
      const lib = await import("pdfjs-dist")
      const { default: workerUrl } = await import("pdfjs-dist/build/pdf.worker.min.mjs?url")
      lib.GlobalWorkerOptions.workerSrc = workerUrl
      ;(window as unknown as { pdfjsLib: typeof lib }).pdfjsLib = lib
    })()
  }
  await pdfjsLoad
  document.dispatchEvent(new CustomEvent("pdfjs:ready"))
})

// Re-fire `turbolinks:load` so legacy scripts under
// app/assets/javascripts/ (noty's flash reader, chart.coffee,
// invoice/offer/project page initializers, the AngularJS
// bootstraps, etc.) keep working under Turbo. We listen to both
// events because each catches a different navigation shape:
//
// - `turbo:load`: initial page load + Turbo Drive visits.
// - `turbo:render`: also fires after form-error responses (e.g.
//   Devise's 422 on a failed sign-in), where `turbo:load` doesn't.
//   Without re-firing here, the layout's
//   `<body data-error="…">` from `flash[:alert]` never reaches
//   `helpers/noty.coffee` and the user sees no error toast.
//
// Both events can fire for the same navigation (turbo:render +
// turbo:load on a Drive visit, and turbo:render fires twice on
// visits served from cache). Fingerprint the body's flash data
// attrs and only re-dispatch when they change so the legacy
// handlers don't run repeatedly.
let lastFlashFingerprint = ""
const refireTurbolinksLoad = () => {
  const ds = document.body?.dataset
  const fingerprint = [ds?.success, ds?.info, ds?.alert, ds?.warning, ds?.error].join("|")
  if (fingerprint === lastFlashFingerprint) return
  lastFlashFingerprint = fingerprint
  document.dispatchEvent(new CustomEvent("turbolinks:load"))
}
document.addEventListener("turbo:load", refireTurbolinksLoad)
document.addEventListener("turbo:render", refireTurbolinksLoad)

// accounting.js was previously loaded from Sprockets
// (`//= require accounting.js/accounting`) and configured by
// `App.Accounting.init` (CoffeeScript). Now it ships from npm via
// Vite; we configure the currency/number formats from the
// Sprockets-set `window.I18n` and re-expose `window.accounting`
// for the remaining CoffeeScript consumer (`app/chart.coffee`).
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const i18nGlobal = (window as any).I18n
if (i18nGlobal) {
  configureAccounting(i18nGlobal)
  installAccountingGlobal()
}

// moment.js stays loaded from Sprockets (still consumed by
// chart.coffee + AngularJS as a global). Just configure the locale
// + ISO week here, replacing what `App.Moment.init` used to do.
configureMomentLocale()

// Phase 6 — Vue 3 islands. The real timesheet + timers-calendar
// ports live under `app/frontend/islands/<name>/`; for now we just
// ship the foundation: Vue is installed, Vite knows how to compile
// `.vue` SFCs, and the mounter walks `[data-island]` elements on
// every Turbo navigation. The placeholder `hello` island acts as
// a smoke test — drop `<div data-island="hello"></div>` into any
// view and the SFC renders.
const islandRegistry = {
  hello: Hello,
  "timers-calendar": TimersCalendar,
}
mountIslands(islandRegistry)
document.addEventListener("turbo:load", () => mountIslands(islandRegistry))

const application = Application.start()

// Vite glob: every `*_controller.ts` under app/frontend/controllers/
// is bundled and registered. File `tabs_controller.ts` exporting a
// default class becomes `data-controller="tabs"`.
const controllers = import.meta.glob<{ default: typeof import("@hotwired/stimulus").Controller }>(
  "../controllers/*_controller.ts",
  { eager: true },
)

for (const path in controllers) {
  const name = path
    .split("/")
    .pop()!
    .replace(/_controller\.ts$/, "")
    .replace(/_/g, "-")
  application.register(name, controllers[path].default)
}

// Expose for browser-console debugging only in dev.
if (import.meta.env.DEV) {
  ;(window as unknown as { Stimulus?: Application }).Stimulus = application
}

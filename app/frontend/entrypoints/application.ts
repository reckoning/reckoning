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

// `turbo:load` fires once on the initial page load AND on every Turbo
// navigation. Re-emit it as `turbolinks:load` so legacy scripts under
// app/assets/javascripts/ (noty, charts, datepickers, the AngularJS
// bootstraps, etc.) keep wiring themselves up after each navigation.
document.addEventListener("turbo:load", () => {
  document.dispatchEvent(new CustomEvent("turbolinks:load"))
})

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

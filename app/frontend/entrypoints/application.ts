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

// `turbo:load` fires once on the initial page load AND on every Turbo
// navigation. Re-emit it as `turbolinks:load` so legacy scripts under
// app/assets/javascripts/ (noty, charts, datepickers, the AngularJS
// bootstraps, etc.) keep wiring themselves up after each navigation.
document.addEventListener("turbo:load", () => {
  document.dispatchEvent(new CustomEvent("turbolinks:load"))
})

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

// Vite entrypoint — modern asset pipeline lives here.
//
// Loaded on every page via `<%= vite_typescript_tag "application" %>`
// in app/views/layouts/_head.html.erb alongside the legacy Sprockets
// bundle.
//
// Phase 4a of the frontend migration:
// - Turbo is imported but DRIVE IS DISABLED. Turbolinks (legacy gem)
//   still owns page navigation. Phase 4b flips the switch and drops
//   Turbolinks.
// - Stimulus IS started — fully additive, no conflict with the legacy
//   stack. Controllers under app/frontend/controllers/ auto-register
//   by filename (e.g. `tabs_controller.ts` → `data-controller="tabs"`).
// - A `turbo:load → turbolinks:load` shim is installed so that when
//   4b flips Turbo on, the 20+ existing `document.addEventListener
//   ("turbolinks:load", …)` callsites in app/assets/javascripts/
//   keep firing. The shim is a no-op today because Turbo isn't
//   driving navigation yet.

import { session } from "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"

// Disable Turbo Drive until Phase 4b. Turbo 8's module side-effect
// calls `start()` on import; flipping `drive` to false immediately
// after keeps Turbo dormant so Turbolinks (still installed via
// Sprockets) keeps owning navigation.
session.drive = false

// `turbo:load` fires once on the initial page load (and again on every
// Turbo navigation once drive is enabled). Re-emit it as
// `turbolinks:load` so legacy scripts under app/assets/javascripts/
// keep working when 4b removes Turbolinks.
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

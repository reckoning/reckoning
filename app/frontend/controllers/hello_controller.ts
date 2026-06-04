import { Controller } from "@hotwired/stimulus"

// Smoke-test controller. Confirms the Vite glob registry is working
// end-to-end. Drop a `<div data-controller="hello"></div>` anywhere
// in a view and the text "Stimulus is live." appears.
//
// Real controllers replace legacy jQuery sprinkles one at a time
// starting in Phase 5 — see docs/frontend-migration-plan.md.
export default class extends Controller {
  connect() {
    this.element.textContent = "Stimulus is live."
  }
}

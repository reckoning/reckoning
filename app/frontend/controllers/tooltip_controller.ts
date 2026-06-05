import { Controller } from "@hotwired/stimulus"

// Replaces the document-level `$('[data-toggle=tooltip]').tooltip()`
// call that ran inside `App.init`. Attaching per-element via
// Stimulus means tooltips re-initialize on Turbo Frame swap —
// useful since several tooltipped buttons (e.g. the project list's
// "add invoice for customer" hint button) live inside Phase 5's
// `projects-list` frame.
//
// Bootstrap 3's tooltip plugin lives on jQuery, which is still
// loaded via the Sprockets bundle. The controller stays attached
// to `data-toggle="tooltip"` elements so the existing markup
// convention still tells the reader "this has a tooltip".

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const jq: any = (window as unknown as { $: unknown }).$ ?? null

export default class extends Controller {
  connect() {
    if (!jq) return
    jq(this.element).tooltip()
  }

  disconnect() {
    if (!jq) return
    // Bootstrap 3's `tooltip("destroy")` removes the popup + the
    // event bindings so a re-mounted element doesn't accumulate them.
    jq(this.element).tooltip("destroy")
  }
}

import { Controller } from "@hotwired/stimulus"

// Wraps the legacy `window.Datepicker` (pickadate.js) per element so
// it survives Turbo Frame swaps — Stimulus reconnects whenever the
// element is re-added to the DOM, where the old document-level
// `turbolinks:load` init only fired on full page loads.
//
// `window.Datepicker` itself stays in
// `app/assets/javascripts/helpers/datetimepicker.coffee` because the
// AngularJS directives still call `Datepicker.init` directly. Once
// AngularJS leaves in Phase 7, that helper moves into Vite too.
//
// Attach via `data-controller="datepicker"` on the
// `<div class="input-group datepicker">` wrapper. The input inside
// is what pickadate binds to.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Picker = { stop?: () => void } | null
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const jq: any = (window as unknown as { $: unknown }).$ ?? null
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const Datepicker: any = (window as unknown as { Datepicker: unknown }).Datepicker ?? null

export default class extends Controller {
  private picker: Picker = null

  connect() {
    if (!jq || !Datepicker) return
    const input = jq(this.element).find("input")
    if (!input.length) return
    this.picker = Datepicker.init(input)
  }

  disconnect() {
    // pickadate's picker holds a popup + jQuery event bindings.
    // Without `.stop()`, repeatedly swapping a Turbo Frame
    // containing a datepicker would leak one picker per swap.
    this.picker?.stop?.()
    this.picker = null
  }
}

import { Controller } from "@hotwired/stimulus"

// Wraps the selectize.js jQuery plugin per element so the picker
// survives Turbo Frame swaps. The previous `App.Selectize` class
// inited from a document-level `turbolinks:load` handler — that
// missed any select that entered the DOM via a frame swap.
//
// Attach via `data-controller="selectize"`. selectize.js is loaded
// from the legacy Sprockets bundle (vendor bower component) and
// extends jQuery globally; we just call `$el.selectize()` here.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SelectizeInstance = { destroy?: () => void } | null
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const jq: any = (window as unknown as { $: unknown }).$ ?? null

export default class extends Controller {
  private selectize: SelectizeInstance = null

  connect() {
    if (!jq) return
    const $el = jq(this.element).selectize()
    this.selectize = $el[0]?.selectize ?? null
  }

  disconnect() {
    // selectize attaches event listeners + builds a hidden DOM
    // companion alongside the original `<select>`. Without
    // `.destroy()`, repeated frame swaps leak both.
    this.selectize?.destroy?.()
    this.selectize = null
  }
}

import { Controller } from "@hotwired/stimulus"

// Row selection + bulk-action toolbar for the expenses list.
//
// Attach via `data-controller="bulk-select"` on the wrapping form.
// Tag each row checkbox with `data-bulk-select-target="checkbox"`, the
// header "select all" checkbox with `data-bulk-select-target="selectAll"`,
// the toolbar wrapper (hidden until a row is picked) with `"toolbar"`, and
// a selected-count label with `"count"`.
export default class extends Controller {
  static targets = ["checkbox", "selectAll", "toolbar", "count"]
  declare readonly checkboxTargets: HTMLInputElement[]
  declare readonly selectAllTarget: HTMLInputElement
  declare readonly hasSelectAllTarget: boolean
  declare readonly toolbarTarget: HTMLElement
  declare readonly hasToolbarTarget: boolean
  declare readonly countTargets: HTMLElement[]

  connect() {
    this.refresh()
  }

  toggleAll() {
    for (const checkbox of this.checkboxTargets) checkbox.checked = this.selectAllTarget.checked
    this.refresh()
  }

  refresh() {
    const selected = this.selectedCount

    if (this.hasToolbarTarget) this.toolbarTarget.classList.toggle("hide", selected === 0)
    for (const label of this.countTargets) label.textContent = String(selected)

    if (this.hasSelectAllTarget) {
      const total = this.checkboxTargets.length
      this.selectAllTarget.checked = total > 0 && selected === total
      this.selectAllTarget.indeterminate = selected > 0 && selected < total
    }
  }

  private get selectedCount(): number {
    return this.checkboxTargets.filter((checkbox) => checkbox.checked).length
  }
}

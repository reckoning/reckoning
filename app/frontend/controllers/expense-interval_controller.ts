import { Controller } from "@hotwired/stimulus"

// Replaces `app/assets/javascripts/app/expense.coffee`. Shows the
// single `.js-toggle-interval-once` date field when the user picks
// the `once` interval, and the started_at + ended_at pair
// (`.js-toggle-interval-other`) for any recurring interval.
//
// Attach via `data-controller="expense-interval"` on the form.
// Tag the interval `<select>` with `data-action="change->expense-
// interval#toggle"`. Tag each toggleable wrapper with
// `data-expense-interval-target="once"` or `"other"` (multiple
// `other` targets supported — the form has two date pickers in
// the recurring case).

export default class extends Controller {
  static targets = ["once", "other"]
  declare readonly onceTargets: HTMLElement[]
  declare readonly otherTargets: HTMLElement[]

  toggle(event: Event) {
    const select = event.target as HTMLSelectElement
    this.applyVisibility(select.value === "once")
  }

  private applyVisibility(showOnce: boolean) {
    for (const el of this.onceTargets) el.classList.toggle("hide", !showOnce)
    for (const el of this.otherTargets) el.classList.toggle("hide", showOnce)
  }
}

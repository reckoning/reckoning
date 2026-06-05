import { Controller } from "@hotwired/stimulus"

// Replaces `app/assets/javascripts/app/project.coffee`. Keeps the
// project form's rate / budget / budget_hours inputs in sync:
//
// - Editing `budget` recomputes `budget_hours` (= budget / rate)
// - Editing `budget_hours` recomputes `budget` (= budget_hours * rate)
// - Editing `rate` recomputes `budget_hours` from the current budget
//
// All three calculations no-op when rate is zero or empty so we
// don't divide-by-zero or wipe the entered budget.
//
// Attach via `data-controller="project-budget"` on the form. Each
// input gets a `data-action="change->project-budget#..."` plus a
// `data-project-budget-target="..."` so the controller can read
// the others without DOM queries.

export default class extends Controller {
  static targets = ["rate", "budget", "budgetHours"]
  declare readonly rateTarget: HTMLInputElement
  declare readonly budgetTarget: HTMLInputElement
  declare readonly budgetHoursTarget: HTMLInputElement

  budgetChanged() {
    const rate = this.parsedRate()
    if (rate <= 0) return
    const budget = parseFloat(this.budgetTarget.value)
    if (Number.isNaN(budget)) return
    this.budgetHoursTarget.value = (budget / rate).toFixed(2)
  }

  budgetHoursChanged() {
    const rate = this.parsedRate()
    if (rate <= 0) return
    const hours = parseFloat(this.budgetHoursTarget.value)
    if (Number.isNaN(hours)) return
    this.budgetTarget.value = (hours * rate).toFixed(2)
  }

  rateChanged() {
    const rate = this.parsedRate()
    if (rate <= 0) return
    const budget = parseFloat(this.budgetTarget.value)
    if (Number.isNaN(budget)) return
    this.budgetHoursTarget.value = (budget / rate).toFixed(2)
  }

  private parsedRate(): number {
    const rate = parseFloat(this.rateTarget.value)
    return Number.isNaN(rate) ? 0 : rate
  }
}

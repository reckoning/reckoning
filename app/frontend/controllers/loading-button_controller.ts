import { Controller } from "@hotwired/stimulus"

// Replaces `$('.btn.btn-loading').click(-> $(@).button('loading'))`
// from App.init. Bootstrap 3's `button('loading')` swaps the
// button label with `data-loading-text` and disables it while a
// submit is in flight. Pairs with Ladda for the spinner.
//
// Attach via `data-controller="loading-button"` on any submit
// button that should flip into the loading state on click. Used
// across the Devise sign-in/forgot-password/reset-password forms
// and the new-account signup form.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const jq: any = (window as unknown as { $: unknown }).$ ?? null

export default class extends Controller {
  private boundOnClick = () => this.onClick()

  connect() {
    this.element.addEventListener("click", this.boundOnClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundOnClick)
  }

  private onClick() {
    if (!jq) return
    jq(this.element).button("loading")
  }
}

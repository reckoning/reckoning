import { type Page } from "@playwright/test"

// Reckoning has two confirm flows, both rendered by noty's `bottom`
// layout (`ul#noty_bottom_layout_container`) with OK / Cancel as
// `.noty_buttons button:{first,last}-child`:
//
// 1. `[data-notyConfirm]` — the legacy CoffeeScript handler in
//    app/assets/javascripts/helpers/noty.coffee.
// 2. `window.notyConfirm(message, ok, cancel)` — the same dialog
//    called directly, including from the Vue islands via
//    `app/frontend/lib/confirm.ts`.
//
// `data-turbo-confirm` uses the native `window.confirm` instead; drive
// that with `page.on("dialog", …)`.
export default class Confirm {
  private readonly dialogs = "#noty_bottom_layout_container .noty_bar"

  constructor(private readonly page: Page) {}

  // noty only drops a bar once its fade-out finishes, so an
  // already-answered dialog can still be in the DOM — always act on the
  // newest one.
  private get dialog() {
    return this.page.locator(this.dialogs).last()
  }

  async accept() {
    await this.dialog.locator(".noty_buttons button").first().click()
  }

  async cancel() {
    await this.dialog.locator(".noty_buttons button").last().click()
  }

  async waitForClosed() {
    await this.page.locator(this.dialogs).first().waitFor({ state: "detached" })
  }
}

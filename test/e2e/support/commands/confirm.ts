import { type Page } from "@playwright/test"

// Reckoning has two confirm flows:
//
// 1. `[data-notyConfirm]` — the legacy CoffeeScript handler in
//    app/assets/javascripts/helpers/noty.coffee shows a noty bottom-
//    layout dialog with OK / Cancel buttons rendered as
//    `#noty-confirm .noty_buttons button:{first,last}-child`.
//
// 2. `data-turbo-confirm` — Turbo's native confirm uses `window.confirm`
//    by default. If we ever wire it up via `Turbo.setConfirmMethod`
//    to a custom dialog, add a helper here.
//
// This class targets the legacy noty flow that's actually in use today.
export default class Confirm {
  constructor(private readonly page: Page) {}

  async accept() {
    await this.page.locator("#noty-confirm .noty_buttons button:first-child").click()
  }

  async cancel() {
    await this.page.locator("#noty-confirm .noty_buttons button:last-child").click()
  }
}

import { expect, type Page } from "@playwright/test"

// Reckoning's flash messages are rendered via noty 2.x (see
// app/assets/javascripts/helpers/noty.coffee). noty builds each
// toast as `<div class="noty_bar noty_type_<level>"><div class="noty_message">
// <span class="noty_text">…</span>…</div></div>` — single
// underscores, text in `.noty_text`.
//
// Levels match the `displayNoty(type)` argument, which maps from
// the body `data-{level}` attribute → noty type:
//   data-success → success
//   data-info    → information   (noty's name for "info")
//   data-alert   → alert
//   data-warning → warning
//   data-error   → error
export default class Notification {
  constructor(private readonly page: Page) {}

  async success(message: string) {
    await this.expectByLevel("success", message)
  }

  async alert(message: string) {
    await this.expectByLevel("alert", message)
  }

  async error(message: string) {
    await this.expectByLevel("error", message)
  }

  async info(message: string) {
    await this.expectByLevel("information", message)
  }

  async warning(message: string) {
    await this.expectByLevel("warning", message)
  }

  private async expectByLevel(level: string, message: string) {
    const noty = this.page.locator(`.noty_bar.noty_type_${level} .noty_text`, { hasText: message })
    await expect(noty).toBeVisible({ timeout: 10_000 })
    // Click to dismiss so it doesn't shadow later assertions.
    await noty.click()
  }
}

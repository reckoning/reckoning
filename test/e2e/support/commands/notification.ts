import { expect, type Page } from "@playwright/test"

// Reckoning's flash messages are rendered via noty (see
// app/assets/javascripts/helpers/noty.coffee). The DOM matches
// noty's defaults — `.noty_type__<level>` + `.noty_body` inside.
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
    const noty = this.page.locator(`.noty_type__${level} .noty_body`, { hasText: message })
    await expect(noty).toBeVisible({ timeout: 10_000 })
    // Click to dismiss so it doesn't shadow later assertions.
    await noty.click()
  }
}

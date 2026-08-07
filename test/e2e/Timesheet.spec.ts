import {test, expect, type Page} from "./support/commands"
import {app, appScenario} from "./support/on-rails"

// End-to-end for the Phase 6c week-view Vue island. The grid is gated
// behind Flipper `:new_timesheet` (enabled in the scenario) and reads
// tasks from `/api/v1/tasks?weekDate=...` using the Bearer token the
// layout injects into `window.ApiHeaders`.
test.describe("Timesheet week view", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("timesheet_week")
  })

  async function signIn(page: Page) {
    await page.goto("/signin")
    await page.locator("input[name='user[email]']").fill("will@star.fleet")
    await page.locator("input[name='user[password]']").fill("enterprise")
    await page.getByTestId("submit-login").click()
    await expect(page.locator(".user-email")).toContainText("will@star.fleet")
  }

  test("renders the seeded task row with its week total", async ({page}) => {
    await signIn(page)
    await page.goto("/timesheet?view=week")

    await expect(page.locator(".timesheet-week-page")).toBeVisible()

    const row = page.locator(".panel").filter({hasText: "E2E Task"})
    await expect(row.locator(".timesheet-task")).toContainText("E2E Project")
    await expect(row.locator(".timesheet-task")).toContainText("E2E Task")

    // Monday cell pre-filled from the seeded 1h timer → row sum 1:00.
    await expect(row.locator(".timesheet-row-sum")).toContainText("1:00")
  })

  test("autosaves a cell edit and recomputes the row total", async ({page}) => {
    await signIn(page)
    await page.goto("/timesheet?view=week")

    const row = page.locator(".panel").filter({hasText: "E2E Task"})
    const inputs = row.locator(".timesheet-days input")

    // Tuesday (index 1) is empty; adding 2h takes the row from 1:00 to 3:00.
    await inputs.nth(1).fill("2:00")
    await inputs.nth(1).blur()

    await expect(row.locator(".timesheet-row-sum")).toContainText("3:00")
  })
})

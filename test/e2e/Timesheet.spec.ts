import {test, expect, type Page} from "./support/commands"
import {app, appScenario} from "./support/on-rails"

// The timesheet is an SPA page since phase B4 — no Flipper flag, no island
// mount, and its date and view live in the router's query rather than in a
// hash route.
test.describe("Timesheet week view", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("timesheet_week")
  })

  async function signIn(page: Page) {
    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  }

  test("renders the seeded task row with its week total", async ({page}) => {
    await signIn(page)
    await page.goto("/app/timesheet?view=week")

    await expect(page.locator(".timesheet-week-page")).toBeVisible()

    const row = page.getByTestId("task-row").filter({hasText: "E2E Task"})
    await expect(row.locator(".timesheet-task")).toContainText("E2E Project")
    await expect(row.locator(".timesheet-task")).toContainText("E2E Task")

    // Monday cell pre-filled from the seeded 1h timer → row sum 1:00.
    await expect(row.locator(".timesheet-row-sum")).toContainText("1:00")
  })

  // The confirm used to be noty's, drawn by the legacy layout. On an SPA page
  // `confirmDialog` falls back to the browser's own, so the dialog is handled
  // where it now actually appears.
  // The main navigation and the running-timer widget still link
  // `timesheet_path`, and a bookmark carries a date with it.
  test("forwards the old rails path, date and all", async ({ page }) => {
    await signIn(page)

    await page.goto("/timesheet?date=2026-06-10&view=week")

    await expect(page).toHaveURL(/\/app\/timesheet\?date=2026-06-10&view=week$/)
    // A week with nothing tracked in it, so the page itself is the assertion.
    await expect(page.getByText("Heute")).toBeVisible()
  })

  test("removes a row only after the confirm is accepted", async ({page}) => {
    await signIn(page)
    await page.goto("/app/timesheet?view=week")

    const row = page.getByTestId("task-row").filter({hasText: "E2E Task"})
    await expect(row).toBeVisible()

    page.once("dialog", (dialog) => dialog.dismiss())
    await row.locator(".timesheet-task-actions button").click()
    await expect(row).toBeVisible()
    await expect(row.locator(".timesheet-row-sum")).toContainText("1:00")

    page.once("dialog", (dialog) => dialog.accept())
    await row.locator(".timesheet-task-actions button").click()
    await expect(row).toHaveCount(0)
  })

  test("autosaves a cell edit and recomputes the row total", async ({page}) => {
    await signIn(page)
    await page.goto("/app/timesheet?view=week")

    const row = page.getByTestId("task-row").filter({hasText: "E2E Task"})
    const inputs = row.locator(".timesheet-days input")

    // Tuesday (index 1) is empty; adding 2h takes the row from 1:00 to 3:00.
    await inputs.nth(1).fill("2:00")
    await inputs.nth(1).blur()

    await expect(row.locator(".timesheet-row-sum")).toContainText("3:00")
  })
})

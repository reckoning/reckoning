import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The Vue calendar is the only implementation since phase B5 — the AngularJS
// one and the Flipper flag that chose between them are gone. It had no test
// of its own while the flag still stood between it and everyone.
test.describe("Timers calendar", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("timesheet_week")

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  // It lives on the project detail page, which is still server-rendered: the
  // offers and invoices panels around it belong to B6 and B7.
  test("renders on the server-rendered project page", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string

    await page.goto(`/projects/${id}`)

    await expect(page.getByTestId("timers-calendar")).toBeVisible()
  })

  test("shows the month the timers were tracked in", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string
    const month = (await appEval(`I18n.l(Time.zone.now.to_date, format: :month)`)) as string

    await page.goto(`/projects/${id}`)

    await expect(page.getByTestId("timers-calendar")).toContainText(month)
  })
})

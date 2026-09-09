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

  // It lives on the project detail screen, which the old path forwards to.
  test("renders on the project screen the old path forwards to", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string

    await page.goto(`/projects/${id}`)

    await expect(page.getByTestId("timers-calendar")).toBeVisible()
  })

  // The month heading renders whether or not the timers ever arrive, so this
  // asserts the timer itself: the scenario books one hour on the first day of
  // the current week.
  test("shows the timers it loaded", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string

    await page.goto(`/projects/${id}`)

    const calendar = page.getByTestId("timers-calendar")
    await expect(calendar).toBeVisible()

    await expect(calendar.locator(".timer-value")).toHaveText("1:00")
  })

  // The calendar was styled by the server-rendered bundle until the project
  // screen moved; with only `spa.css` loaded its grid collapsed into one long
  // column of day numbers.
  test("lays a week out as seven columns", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string

    await page.goto(`/projects/${id}`)

    const days = page.locator(".bs-calendar-week").first().locator(".bs-calendar-day")
    await expect(days).toHaveCount(7)

    const first = await days.first().boundingBox()
    const last = await days.last().boundingBox()

    expect(first?.y).toBe(last?.y)
    expect(last?.x).toBeGreaterThan((first?.x ?? 0) + (first?.width ?? 0) * 5)
  })

  test("shows the month the timers were tracked in", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string
    const month = (await appEval(`I18n.l(Time.zone.now.to_date, format: :month)`)) as string

    await page.goto(`/projects/${id}`)

    await expect(page.getByTestId("timers-calendar")).toContainText(month)
  })
})

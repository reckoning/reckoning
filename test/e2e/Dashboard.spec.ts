import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B8: the dashboard. Nine panels in the server-rendered one; this covers
// the numbers, the lists and the chart.
test.describe("Dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      customer = Customer.create!(account: account, name: "Starfleet")
      project = customer.projects.create!(name: "Narendra 3", rate: 90, budget: 1000)
      charged = account.invoices.create!(customer: customer, project: project, date: Date.new(2026, 3, 1), ref: 1)
      charged.update_columns(value: 500, workflow_state: "charged", payment_due_date: Date.new(2026, 3, 15))
      paid = account.invoices.create!(customer: customer, project: project, date: Date.new(2026, 4, 1), ref: 2)
      paid.update_columns(value: 250, workflow_state: "paid", pay_date: Date.current)
    `)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })

  test("shows the summary panel with the account's totals", async ({ page }) => {
    await expect(page.getByTestId("summary-panel")).toBeVisible()
    await expect(page.getByTestId("charged-sum")).toContainText("500")
    await expect(page.getByTestId("paid-sum")).toContainText("250")
    // Charged plus paid, as the ERB row added them up.
    await expect(page.getByTestId("all-sum")).toContainText("750")
  })

  test("lists the open and the paid invoices", async ({ page }) => {
    await expect(page.getByTestId("charged-invoices")).toContainText("00001")
    await expect(page.getByTestId("paid-invoices")).toContainText("00002")
  })

  // The chart is the same Highcharts build and the same options the
  // server-rendered dashboard uses: four series — a running total and the
  // months, for this year and the last — with the month in progress banded.
  test("draws the invoice chart", async ({ page }) => {
    const chart = page.getByTestId("invoices-chart")

    await expect(chart.locator("svg")).toBeVisible()
    expect(await chart.locator(".highcharts-series path").count()).toBeGreaterThanOrEqual(4)
    await expect(chart.locator(".highcharts-legend")).toHaveCount(0)
    await expect(chart).toContainText("€")

    // This build hands out almost no class names, so the band over the month
    // in progress is found by the colour it is drawn in.
    await expect(chart.locator('path[fill="rgba(155, 200, 255, 0.2)"]')).toHaveCount(1)
  })

  // The chart is read by hovering it: one tooltip for every series at the
  // month under the pointer, which Highcharts marks with a band.
  test("answers the pointer with the month's figures", async ({ page }) => {
    const chart = page.getByTestId("invoices-chart").locator("svg")
    await expect(chart).toBeVisible()

    const box = await chart.boundingBox()
    if (!box) throw new Error("chart has no box")

    // Two moves: Highcharts starts tracking on the first event over the
    // container, and reads the position from the ones after it.
    await page.mouse.move(box.x + box.width * 0.1, box.y + box.height / 2)
    await page.mouse.move(box.x + box.width * 0.3, box.y + box.height / 2, { steps: 10 })

    // The tooltip's own element has no size — the box belongs to the span
    // inside it, which is what `.highcharts-tooltip > span` styles.
    const tooltip = page.locator(".highcharts-tooltip > span")
    await expect(tooltip).toBeVisible()
    await expect(tooltip).toContainText("€")
    await expect(tooltip.locator(".highcharts-tooltip-header")).toBeVisible()

    // The crosshair is a line as wide as the month, so it reads as a band
    // across the whole category rather than a hairline.
    const crosshair = page.locator('path[stroke="rgba(200, 200, 200, 0.2)"]')
    await expect(crosshair).toHaveCount(1)
    expect(Number(await crosshair.getAttribute("stroke-width"))).toBeGreaterThan(20)
  })

  test("shows a budget bar for a project that has one", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string

    await expect(page.getByTestId("budgets-panel")).toBeVisible()
    await expect(page.getByTestId(`budget-${id}`)).toBeVisible()
  })

  // Weekly and daily hours are always there; a customer only appears once it
  // has a schedule.
  test("shows the hours in the overtime panel", async ({ page }) => {
    await expect(page.getByTestId("weekly-hours")).toBeVisible()
    await expect(page.getByTestId("daily-hours")).toBeVisible()
  })

  // The banner is the SPA's own since the root path stopped serving the
  // server-rendered dashboard, and it had no test of its own.
  test("counts the trial down, and says when it has run out", async ({ page }) => {
    await appEval(`
      Account.find_by(name: "Enterprise")
        .update_columns(plan: "basic", trial_used: true, trial_end_at: 5.days.from_now)
    `)
    await page.reload()

    await expect(page.getByTestId("trial-banner")).toContainText("5")

    await appEval(`
      Account.find_by(name: "Enterprise")
        .update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)
    `)
    await page.reload()

    await expect(page.getByTestId("trial-banner")).toContainText("abgelaufen")
  })

  test("leaves the banner away from an account without a trial", async ({ page }) => {
    await appEval(`
      Account.find_by(name: "Enterprise").update_columns(trial_end_at: nil, trial_used: false)
    `)
    await page.reload()

    await expect(page.getByTestId("trial-banner")).toHaveCount(0)
  })

  test("answers a page load on the root path", async ({ page }) => {
    await page.goto("/")

    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })
})

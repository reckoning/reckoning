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

    await page.goto("/app/login")
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

  // The chart the server-rendered dashboard drew with nvd3, as plain SVG: four
  // series — a running total and the months, for this year and the last.
  //
  // Not `toBeVisible`: last year's series is a flat line at zero, and an
  // element without height counts as invisible.
  test("draws the invoice chart", async ({ page }) => {
    await expect(page.getByTestId("invoices-chart").locator("svg")).toBeVisible()

    const lines = page.getByTestId("invoices-chart").locator("path")

    await expect(lines).toHaveCount(4)
    await expect(lines.first()).toHaveAttribute("d", /^M[\d.]+,[\d.]+ L/)
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

  test("forwards the old rails path to the spa", async ({ page }) => {
    await page.goto("/app/")

    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })
})

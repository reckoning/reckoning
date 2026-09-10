import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The last detail page to move: the budget chart, the four numbers worked out
// from what the project has booked, and the four tabs.
test.describe("Project detail", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      customer = Customer.create!(account: account, name: "Starfleet")
      project = customer.projects.create!(
        name: "Narendra 3", rate: 90, budget: 10_000, budget_hours: 100,
        start_date: 3.weeks.ago, end_date: 1.week.from_now
      )
      task = project.tasks.create!(name: "Away mission", billable: true)
      task.timers.create!(user: account.users.first, date: 2.weeks.ago.to_date, value: 120)
      invoice = account.invoices.create!(customer: customer, project: project, date: Date.current, ref: 1)
      invoice.update_columns(value: 2500)
      offer = account.offers.create!(customer: customer, project: project, date: Date.current, ref: 1)
      offer.update_columns(value: 900)
    `)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  async function projectId() {
    return (await appEval(`Project.find_by(name: "Narendra 3").id`)) as string
  }

  test("draws the budget chart and the numbers under it", async ({ page }) => {
    const id = await projectId()
    await page.goto(`/projects/${id}`)

    await expect(page.getByTestId("project-title")).toContainText("Narendra 3")

    // The same Highcharts build the dashboard uses, and the budget as a line
    // across it — 120 hours at 90 book past the 10.000 budget, so the line
    // falls inside the axis Highcharts works out from the series.
    await expect(page.getByTestId("project-budget-chart").locator("svg")).toBeVisible()
    await expect(
      page.locator('[data-test="project-budget-chart"] .highcharts-plotline-budget'),
    ).toContainText("10.000", { timeout: 15_000 })

    // 120 hours booked, 100 budgeted, 2500 invoiced of 10000, at 90 an hour.
    await expect(page.getByTestId("box-hours")).toContainText("120,00 h")
    await expect(page.getByTestId("box-remaining-hours")).toContainText("-20,00 h")
    await expect(page.getByTestId("box-remaining-budget")).toContainText("7.500")
    await expect(page.getByTestId("box-uninvoiced")).toContainText("10.800")
  })

  test("lists the project's offers, invoices and tasks in their tabs", async ({ page }) => {
    const id = await projectId()
    await page.goto(`/projects/${id}`)

    await page.getByTestId("tab-invoices").click()
    await expect(page).toHaveURL(/#invoices$/)
    await expect(page.getByTestId("invoices")).toContainText("00001")

    await page.getByTestId("tab-offers").click()
    await expect(page.getByTestId("offers")).toContainText("00001")

    await page.getByTestId("tab-tasks").click()
    await expect(page.getByTestId("tasks")).toContainText("Away mission")

    await page.getByTestId("tab-timers").click()
    await expect(page.getByTestId("timers-calendar")).toBeVisible()
  })

  test("opens the tab the url names", async ({ page }) => {
    const id = await projectId()
    await page.goto(`/projects/${id}#tasks`)

    await expect(page.getByTestId("tasks")).toContainText("Away mission")
  })

  // The project screen is where a new invoice for the project starts, and the
  // form reads the project out of the query.
  test("starts a new invoice for the project it is showing", async ({ page }) => {
    const id = await projectId()
    await page.goto(`/projects/${id}`)

    await page.getByTestId("add-invoice").click()

    await expect(page).toHaveURL(new RegExp(`/invoices/new\\?project_id=${id}`))
  })

  test("answers a page load on the detail path", async ({ page }) => {
    const id = await projectId()

    await page.goto(`/projects/${id}`)

    await expect(page).toHaveURL(new RegExp(`/projects/${id}$`))
    await expect(page.getByTestId("project-title")).toContainText("Narendra 3")
  })

  test("is reachable from the project list", async ({ page }) => {
    await page.goto("/projects")

    await page.getByText("Narendra 3").first().click()

    await expect(page).toHaveURL(/\/projects\/[0-9a-f-]+$/)
    await expect(page.getByTestId("budget-panel")).toBeVisible()
  })
})

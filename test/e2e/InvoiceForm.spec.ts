import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B6, last piece: the invoice form and the position editor — the second
// of the two screens Vue was chosen for.
test.describe("Invoice form", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      account.update_columns(contact_information: {"address" => "Sector 001"}, settings: {"tax" => "19"})
      customer = Customer.create!(account: account, name: "Starfleet", contact_information: {"address" => "Earth"})
      project = customer.projects.create!(name: "Narendra 3", rate: 90)
      task = project.tasks.create!(name: "Away mission", billable: true)
      user = User.find_by(email: "will@star.fleet")
      Timer.create!(user: user, task: task, date: Date.current, value: 1.5)
      Timer.create!(user: user, task: task, date: Date.current - 1, value: 0.5)
    `)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("writes an invoice with a hand-typed position", async ({ page }) => {
    const projectId = (await appEval(`Project.first.id`)) as string

    await page.goto(`/invoices/new?project_id=${projectId}`)

    await page.getByTestId("date").fill("2026-03-01")
    await page.getByTestId("position-description-0").fill("Beratung")
    await page.getByTestId("position-hours-0").fill("2")

    // The rate comes from the project and the value follows the hours.
    await expect(page.getByTestId("position-rate-0")).toHaveValue("90.0")
    await expect(page.getByTestId("position-value-computed-0")).toHaveText("180")

    await page.getByTestId("submit").click()

    await expect(page.getByText("Rechnung angelegt.")).toBeVisible()
    // The detail page shows the document rather than repeating its positions.
    await expect(page.getByTestId("invoice-title")).toBeVisible()

    expect(await appEval(`Invoice.last.positions.first.value.to_f`)).toBe(180)
  })

  // The point of the editor: turning tracked time into a position, with the
  // timers carried along so the same hours are never invoiced twice.
  test("generates a position from uninvoiced time", async ({ page }) => {
    const projectId = (await appEval(`Project.first.id`)) as string

    await page.goto(`/invoices/new?project_id=${projectId}`)
    await page.getByTestId("date").fill("2026-03-01")

    await page.getByTestId("generate-positions").click()

    const taskId = (await appEval(`Task.first.id`)) as string
    await expect(page.getByTestId(`candidate-${taskId}`)).toContainText("Away mission")
    await expect(page.getByTestId(`candidate-${taskId}`)).toContainText("2 h")

    await page.getByTestId(`candidate-${taskId}`).locator("input").check()
    await page.getByTestId("take-picked").click()

    await expect(page.getByTestId("position-hours-fixed-1")).toContainText("2")

    await page.getByTestId("submit").click()
    await expect(page.getByText("Rechnung angelegt.")).toBeVisible()

    // Both timers now belong to the position, which is what keeps them out of
    // the next invoice — `invoiced` is derived from exactly that link.
    expect(await appEval(`Invoice.last.timers.count`)).toBe(2)
    expect(await appEval(`Timer.where.not(position_id: nil).count`)).toBe(2)
    expect(await appEval(`Invoice.last.positions.first.value.to_f`)).toBe(180)
  })

  test("offers only time that is not on an invoice yet", async ({ page }) => {
    const projectId = (await appEval(`Project.first.id`)) as string
    await appEval(`
      invoice = Account.find_by(name: "Enterprise").invoices.create!(
        customer: Customer.first, project: Project.first, date: Date.new(2026, 2, 1), ref: 1
      )
      position = invoice.positions.create!(description: "Alt", hours: 1.5, rate: 90)
      position.timers << Timer.order(:date).last
    `)

    await page.goto(`/invoices/new?project_id=${projectId}`)
    await page.getByTestId("generate-positions").click()

    const taskId = (await appEval(`Task.first.id`)) as string
    // One timer is spoken for, so only the other half hour is left.
    await expect(page.getByTestId(`candidate-${taskId}`)).toContainText("0.5 h")
  })

  test("edits an existing invoice and removes a position", async ({ page }) => {
    await appEval(`
      invoice = Account.find_by(name: "Enterprise").invoices.create!(
        customer: Customer.first, project: Project.first, date: Date.new(2026, 3, 1), ref: 7
      )
      invoice.positions.create!(description: "Alt", hours: 1, rate: 90)
      invoice.positions.create!(description: "Bleibt", hours: 2, rate: 90)
      invoice.save!
    `)
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}/edit`)

    await expect(page.getByTestId("position-description-0")).toHaveValue("Alt")

    await page.getByTestId("position-remove-0").click()
    await page.getByTestId("submit").click()

    await expect(page.getByText("Rechnung gespeichert.")).toBeVisible()

    const remaining = await appEval(`Invoice.first.positions.pluck(:description)`)
    expect(remaining).toEqual(["Bleibt"])
  })

  test("answers a page load on the form paths", async ({ page }) => {
    const id = (await appEval(`Project.first.id`)) as string

    await page.goto(`/invoices/new?project_id=${id}`)
    await expect(page).toHaveURL(new RegExp(`/invoices/new\\?project_id=${id}$`))
  })

  // The ERB form rendered the project select for `new` and `edit` alike. Time
  // tracked against the old project cannot follow the invoice, so the
  // generated position goes with the project it came from.
  test("moves an invoice to another project", async ({ page }) => {
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      customer = Customer.find_by(name: "Starfleet")
      customer.projects.create!(name: "Outpost 6", rate: 50)
      invoice = account.invoices.create!(customer: customer, project: Project.find_by(name: "Narendra 3"), date: Date.new(2026, 3, 1), ref: 1)
      position = invoice.positions.create!(description: "Away mission", hours: 2, rate: 90)
      position.timers << Timer.first
      invoice.save!
    `)
    const id = (await appEval(`Invoice.first.id`)) as string
    const other = (await appEval(`Project.find_by(name: "Outpost 6").id`)) as string

    await page.goto(`/invoices/${id}/edit`)

    await expect(page.getByTestId("position-description-0")).toHaveValue("Away mission")

    await page.getByTestId("project").selectOption(other)
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("invoice-title")).toBeVisible()
    expect(await appEval(`Invoice.first.project.name`)).toBe("Outpost 6")
    expect(await appEval(`Invoice.first.positions.count`)).toBe(0)
  })
})

import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B3: the project list and form moved into the SPA. The detail page is
// still server-rendered — it carries the offers and invoices panels, which
// belong to B6 and B7.
test.describe("Projects", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      account.update_columns(contact_information: {"address" => "Sector 001"})
      customer = Customer.create!(account: account, name: "Starfleet")
      project = customer.projects.create!(name: "Narendra 3", rate: 90, budget: 1000, budget_hours: 20)
      project.tasks.create!(name: "Away mission", billable: true)
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("lists projects under their customer and edits one", async ({ page }) => {
    await page.goto("/app/projects")

    await expect(page.getByRole("heading", { name: "Starfleet" })).toBeVisible()
    await expect(page.getByText("Narendra 3")).toBeVisible()

    await page.getByText("Bearbeiten").first().click()

    await expect(page.getByTestId("name")).toHaveValue("Narendra 3")
    await expect(page.getByTestId("task-name-0")).toHaveValue("Away mission")

    await page.getByTestId("name").fill("Narendra III")
    await page.getByTestId("submit").click()

    await expect(page.getByText("Projekt gespeichert.")).toBeVisible()
    expect(await appEval(`Project.find_by(name: "Narendra III").present?`)).toBe(true)
  })

  test("adds a task to a project", async ({ page }) => {
    const id = (await appEval(`Project.find_by(name: "Narendra 3").id`)) as string

    await page.goto(`/app/projects/${id}/edit`)
    await page.getByTestId("add-task").click()
    await page.getByTestId("task-name-1").fill("Shore leave")
    await page.getByTestId("submit").click()

    await expect(page.getByText("Projekt gespeichert.")).toBeVisible()

    const names = await appEval(`Project.find_by(name: "Narendra 3").tasks.order(:name).pluck(:name)`)
    expect(names).toEqual(["Away mission", "Shore leave"])
  })

  test("archives a project and finds it under the archived filter", async ({ page }) => {
    await page.goto("/app/projects")

    page.once("dialog", (dialog) => dialog.accept())
    await page.getByText("Archivieren").first().click()

    await expect(page.getByText("Projekt archiviert.")).toBeVisible()
    await expect(page.getByTestId("empty")).toBeVisible()

    await page.getByTestId("filter-archived").click()
    await expect(page.getByText("Narendra 3")).toBeVisible()
  })

  // The main navigation still links `projects_path`, and so do bookmarks.
  test("forwards the old rails paths to the spa", async ({ page }) => {
    await page.goto("/projects")
    await expect(page).toHaveURL(/\/app\/projects$/)

    await page.goto("/projects/new")
    await expect(page).toHaveURL(/\/app\/projects\/new$/)
  })

  // Deleting the guard with the ERB screen would have let a project be created
  // for an account that cannot issue an invoice.
  test("refuses a new project while the account has no address", async ({ page }) => {
    await appEval(`Account.find_by(name: "Enterprise").update_columns(contact_information: {})`)

    await page.goto("/app/projects/new")

    await expect(page.getByTestId("missing-address")).toBeVisible()
    await expect(page.getByTestId("name")).toHaveCount(0)
  })
})

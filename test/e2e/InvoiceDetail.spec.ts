import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B6: the invoice detail page, including the PDF previews it used to
// render through the legacy pdf.js loader.
test.describe("Invoice detail", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      account.update_columns(contact_information: {"address" => "Sector 001"}, settings: {"tax" => "19"})
      customer = Customer.create!(account: account, name: "Starfleet", contact_information: {"address" => "Earth"})
      project = customer.projects.create!(name: "Narendra 3", rate: 90)
      invoice = account.invoices.create!(customer: customer, project: project, date: Date.new(2026, 3, 1), ref: 1)
      invoice.positions.create!(description: "Away mission", hours: 2, rate: 90)
      invoice.save!
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("shows the invoice, its positions and its state", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/app/invoices/${id}`)

    await expect(page.getByTestId("invoice-title")).toContainText("00001")
    await expect(page.getByTestId("positions")).toContainText("Away mission")
    await expect(page.getByTestId("state")).toContainText("Erstellt")
  })

  // The point of porting the viewer rather than linking out: pdf.js has to
  // work inside the SPA bundle, worker and all.
  test("renders the invoice PDF inline", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/app/invoices/${id}`)

    await expect(page.locator('[data-test="pdf-pages"] canvas').first()).toBeVisible({ timeout: 60_000 })
  })

  test("charges and then pays the invoice", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/app/invoices/${id}`)

    page.once("dialog", (dialog) => dialog.accept())
    await page.getByTestId("charge").click()

    await expect(page.getByText("Rechnung gestellt.")).toBeVisible()
    await expect(page.getByTestId("pay")).toBeVisible()

    await page.getByTestId("pay").click()
    await expect(page.getByText("Als bezahlt markiert.")).toBeVisible()

    expect(await appEval(`Invoice.first.workflow_state`)).toBe("paid")
  })

  test("leaves the invoice alone when the charge confirm is declined", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/app/invoices/${id}`)

    page.once("dialog", (dialog) => dialog.dismiss())
    await page.getByTestId("charge").click()

    await expect(page.getByTestId("charge")).toBeVisible()
    // Declining is not a failure, and it used to say so anyway.
    await expect(page.getByText("Aktion fehlgeschlagen.")).toHaveCount(0)
    expect(await appEval(`Invoice.first.workflow_state`)).toBe("created")
  })

  // An expired trial reads everything and writes nothing. Offering the
  // buttons anyway means a 403 for every click.
  test("offers no write actions once the trial has run out", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string
    await appEval(`
      Account.find_by(name: "Enterprise")
        .update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)
    `)

    await page.goto(`/app/invoices/${id}`)

    await expect(page.getByTestId("invoice-title")).toContainText("00001")
    await expect(page.getByTestId("charge")).toHaveCount(0)
    await expect(page.getByTestId("edit")).toHaveCount(0)
    await expect(page.getByTestId("delete")).toHaveCount(0)
  })

  test("forwards the old rails path to the spa", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}`)

    await expect(page).toHaveURL(new RegExp(`/app/invoices/${id}$`))
    await expect(page.getByTestId("invoice-title")).toContainText("00001")
  })
})

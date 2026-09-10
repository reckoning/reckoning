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

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  // The server-rendered screen put the document itself on the page rather
  // than repeating its numbers beside it.
  test("shows the invoice, its state and its downloads", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}`)

    await expect(page.getByTestId("invoice-title")).toContainText("00001")
    await expect(page.getByTestId("state")).toContainText("Entwurf")
    await expect(page.getByTestId("invoice-pdf")).toBeVisible()
  })

  // Each action is the whole row, and the ones that navigate are real links:
  // an `href` is what gives the row its pointer, its middle-click and its
  // "open in a new tab".
  test("makes every action row the control across its full width", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}`)

    const edit = page.getByTestId("edit")
    await expect(edit).toHaveAttribute("href", `/invoices/${id}/edit`)

    const box = await edit.boundingBox()
    if (!box) throw new Error("the edit row has no box")

    // The row's far edge, well past the label, still hits the control.
    const target = await page.evaluate(
      ([x, y]) => document.elementFromPoint(x, y)?.getAttribute("data-test"),
      [box.x + box.width - 10, box.y + box.height / 2],
    )

    expect(target).toBe("edit")
  })

  // The ring the server-rendered viewer spun over the empty preview. Held up
  // on purpose, because a PDF that arrives at once never shows it.
  test("spins while the preview is still loading", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.route("**/pdf/**", async (route) => {
      await new Promise((resolve) => setTimeout(resolve, 3000))
      await route.continue()
    })

    await page.goto(`/invoices/${id}`)

    await expect(page.getByTestId("pdf-loading")).toBeVisible()

    await expect(page.locator('[data-test="pdf-pages"] canvas').first()).toBeVisible({
      timeout: 60_000,
    })
    await expect(page.getByTestId("pdf-loading")).toHaveCount(0)
  })

  // The point of porting the viewer rather than linking out: pdf.js has to
  // work inside the SPA bundle, worker and all.
  test("renders the invoice PDF inline", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}`)

    await expect(page.locator('[data-test="pdf-pages"] canvas').first()).toBeVisible({ timeout: 60_000 })
  })

  test("charges and then pays the invoice", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}`)

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

    await page.goto(`/invoices/${id}`)

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

    await page.goto(`/invoices/${id}`)

    await expect(page.getByTestId("invoice-title")).toContainText("00001")
    await expect(page.getByTestId("charge")).toHaveCount(0)
    await expect(page.getByTestId("edit")).toHaveCount(0)
    await expect(page.getByTestId("delete")).toHaveCount(0)
  })

  test("answers a page load on the detail path", async ({ page }) => {
    const id = (await appEval(`Invoice.first.id`)) as string

    await page.goto(`/invoices/${id}`)

    await expect(page).toHaveURL(new RegExp(`/invoices/${id}$`))
    await expect(page.getByTestId("invoice-title")).toContainText("00001")
  })
})

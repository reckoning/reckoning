import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B7: the offer detail page, its PDF preview, and the state machine —
// which no server-rendered screen ever offered a button for.
test.describe("Offer detail", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      account.update_columns(contact_information: {"address" => "Sector 001"}, settings: {"tax" => "19"})
      customer = Customer.create!(account: account, name: "Starfleet", contact_information: {"address" => "Earth"})
      project = customer.projects.create!(name: "Narendra 3", rate: 90)
      offer = account.offers.create!(customer: customer, project: project, date: Date.new(2026, 3, 1), ref: 1, description: "Sector survey")
      offer.positions.create!(description: "Away mission", hours: 2, rate: 90)
      offer.save!
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("shows the offer, its positions and its state", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string

    await page.goto(`/app/offers/${id}`)

    await expect(page.getByTestId("offer-title")).toContainText("00001")
    await expect(page.getByTestId("positions")).toContainText("Away mission")
    await expect(page.getByTestId("state")).toContainText("Entwurf")
  })

  test("renders the offer PDF inline", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string

    await page.goto(`/app/offers/${id}`)

    await expect(page.locator('[data-test="pdf-pages"] canvas').first()).toBeVisible({ timeout: 60_000 })
  })

  // The endpoint existed since phase A7 and had no consumer: no ERB screen
  // ever rendered a button for it.
  test("walks the offer through its state machine", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string

    await page.goto(`/app/offers/${id}`)

    page.once("dialog", (dialog) => dialog.accept())
    await page.getByTestId("transition-bid").click()

    await expect(page.getByText("Angebot abgegeben.")).toBeVisible()
    await expect(page.getByTestId("transition-accept")).toBeVisible()

    page.once("dialog", (dialog) => dialog.accept())
    await page.getByTestId("transition-accept").click()

    await expect(page.getByText("Angebot angenommen.")).toBeVisible()
    expect(await appEval(`Offer.first.aasm_state`)).toBe("accepted")

    // Nothing follows an accepted offer.
    await expect(page.getByTestId("transition-bid")).toHaveCount(0)
  })

  test("leaves the offer alone when the confirm is declined", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string

    await page.goto(`/app/offers/${id}`)

    page.once("dialog", (dialog) => dialog.dismiss())
    await page.getByTestId("transition-bid").click()

    await expect(page.getByTestId("transition-bid")).toBeVisible()
    await expect(page.getByText("Das hat nicht funktioniert.")).toHaveCount(0)
    expect(await appEval(`Offer.first.aasm_state`)).toBe("created")
  })

  // Editing an offer's content stops at bided, but the machine lets a
  // declined one be bid again — so the buttons come from the endpoint rather
  // than from `editable`.
  test("offers a declined offer again", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string
    await appEval(`
      offer = Offer.first
      offer.bid!
      offer.decline!
    `)

    await page.goto(`/app/offers/${id}`)

    await expect(page.getByTestId("state")).toContainText("Abgelehnt")
    await expect(page.getByTestId("transition-bid")).toBeVisible()
  })

  test("offers no write actions once the trial has run out", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string
    await appEval(`
      Account.find_by(name: "Enterprise")
        .update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)
    `)

    await page.goto(`/app/offers/${id}`)

    await expect(page.getByTestId("offer-title")).toContainText("00001")
    await expect(page.getByTestId("transition-bid")).toHaveCount(0)
    await expect(page.getByTestId("edit")).toHaveCount(0)
    await expect(page.getByTestId("delete")).toHaveCount(0)
  })

  test("forwards the old rails path to the spa", async ({ page }) => {
    const id = (await appEval(`Offer.first.id`)) as string

    await page.goto(`/offers/${id}`)

    await expect(page).toHaveURL(new RegExp(`/app/offers/${id}$`))
    await expect(page.getByTestId("offer-title")).toContainText("00001")
  })
})

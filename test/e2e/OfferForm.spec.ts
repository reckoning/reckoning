import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B7: the offer form and its position editor.
test.describe("Offer form", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      account.update_columns(contact_information: {"address" => "Sector 001"}, settings: {"tax" => "19"})
      customer = Customer.create!(account: account, name: "Starfleet", contact_information: {"address" => "Earth"})
      customer.projects.create!(name: "Narendra 3", rate: 90)
    `)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("writes an offer with a hand-typed position", async ({ page }) => {
    const projectId = (await appEval(`Project.first.id`)) as string

    await page.goto(`/offers/new?project_id=${projectId}`)

    await page.getByTestId("date").fill("2026-08-01")
    await page.getByTestId("description").fill("Sector survey")
    await page.getByTestId("position-description-0").fill("Design")
    await page.getByTestId("position-hours-0").fill("4")

    // The project's rate fills itself in, and the value follows.
    await expect(page.getByTestId("position-rate-0")).toHaveValue("90.0")
    await expect(page.getByTestId("position-value-computed-0")).toHaveText("360")

    await page.getByTestId("submit").click()

    await expect(page.getByTestId("offer-title")).toBeVisible()
    expect(await appEval(`Offer.first.value.to_f`)).toBe(360)
    expect(await appEval(`Offer.first.description`)).toBe("Sector survey")
  })

  test("edits an offer and removes a position", async ({ page }) => {
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      offer = account.offers.create!(project: Project.first, date: Date.new(2026, 3, 1), ref: 1)
      offer.positions.create!(description: "Away mission", hours: 2, rate: 90)
      offer.save!
    `)
    const id = (await appEval(`Offer.first.id`)) as string

    await page.goto(`/offers/${id}/edit`)

    await expect(page.getByTestId("position-description-0")).toHaveValue("Away mission")

    await page.getByTestId("position-remove-0").click()
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("offer-title")).toBeVisible()
    expect(await appEval(`Offer.first.positions.count`)).toBe(0)
  })

  // The ERB form rendered the project select for `new` and `edit` alike.
  test("moves an offer to another project", async ({ page }) => {
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      customer = Customer.find_by(name: "Starfleet")
      customer.projects.create!(name: "Outpost 6", rate: 50)
      offer = account.offers.create!(project: Project.find_by(name: "Narendra 3"), date: Date.new(2026, 3, 1), ref: 1)
      offer.positions.create!(description: "Design", hours: 2, rate: 90)
      offer.save!
    `)
    const id = (await appEval(`Offer.first.id`)) as string
    const other = (await appEval(`Project.find_by(name: "Outpost 6").id`)) as string

    await page.goto(`/offers/${id}/edit`)

    await expect(page.getByTestId("position-description-0")).toHaveValue("Design")

    await page.getByTestId("project").selectOption(other)
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("offer-title")).toBeVisible()
    expect(await appEval(`Offer.first.project.name`)).toBe("Outpost 6")
  })

  // The offer's PDF carries the account address as the sender, and the model
  // refuses the create without one.
  test("refuses a new offer while the account has no address", async ({ page }) => {
    await appEval(`Account.find_by(name: "Enterprise").update_columns(contact_information: {})`)

    await page.goto("/offers/new")

    await expect(page.getByTestId("missing-address")).toBeVisible()
  })

  test("answers a page load on the form paths", async ({ page }) => {
    const projectId = (await appEval(`Project.first.id`)) as string

    await page.goto(`/offers/new?project_id=${projectId}`)

    await expect(page).toHaveURL(new RegExp(`/offers/new\\?project_id=${projectId}$`))
    await expect(page.getByTestId("offer-form-title")).toBeVisible()
  })
})

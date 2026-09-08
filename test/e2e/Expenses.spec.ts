import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The expenses list, the last main navigation entry that had no SPA screen.
// The form and the CSV import are still server-rendered.
test.describe("Expenses", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      # The seeded account carries no plan, so a validating save on it
      # fails — the flag goes in past the validations.
      account.update_columns(feature_expenses: true)
      account.expenses.create!(
        expense_type: "gwg", value: 100, description: "Tricorder",
        seller: "Daystrom Institute", date: Date.new(${new Date().getUTCFullYear()}, 3, 1),
        vat_percent: 19, private_use_percent: 10, interval: "once"
      )
      account.expenses.create!(
        expense_type: "home_office", value: 500, description: "Ready room",
        seller: "Utopia Planitia", date: Date.new(${new Date().getUTCFullYear()}, 4, 1),
        vat_percent: 0, private_use_percent: 0, interval: "once"
      )
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("lists the expenses with what they add up to", async ({ page }) => {
    await page.goto("/app/expenses")

    const list = page.getByTestId("expenses")
    await expect(list).toContainText("Tricorder")
    await expect(list).toContainText("Ready room")

    // 100 at 10% private use deducts 90; the home office deducts nothing
    // while the account has no office space entered.
    await expect(page.getByTestId("summary-value")).toContainText("90")
  })

  // The icon at the end of the row: a business expense files no receipt, a
  // low-value asset does.
  test("says which row is missing its receipt", async ({ page }) => {
    await page.goto("/app/expenses")

    const gwg = (await appEval(`Expense.find_by(description: "Tricorder").id`)) as string
    const office = (await appEval(`Expense.find_by(description: "Ready room").id`)) as string

    await expect(page.getByTestId(`receipt-missing-${gwg}`)).toBeVisible()
    await expect(page.getByTestId(`receipt-missing-${office}`)).toHaveCount(0)
  })

  test("filters by type and keeps it in the url", async ({ page }) => {
    await page.goto("/app/expenses")

    await page.getByTestId("filter-type").click()
    await page.getByTestId("filter-type-home_office").click()

    await expect(page).toHaveURL(/type=home_office/)
    await expect(page.getByTestId("expenses")).toContainText("Ready room")
    await expect(page.getByTestId("expenses")).not.toContainText("Tricorder")
  })

  test("searches the descriptions", async ({ page }) => {
    await page.goto("/app/expenses")

    await page.getByTestId("search").fill("Tric")
    await page.getByTestId("search-submit").click()

    await expect(page).toHaveURL(/query=Tric/)
    await expect(page.getByTestId("expenses")).toContainText("Tricorder")
    await expect(page.getByTestId("expenses")).not.toContainText("Ready room")
  })

  // The bar the server-rendered list slid out once a row was ticked.
  test("applies a change to the rows that were picked", async ({ page }) => {
    await page.goto("/app/expenses")

    const id = (await appEval(`Expense.find_by(description: "Tricorder").id`)) as string

    await page.getByTestId(`select-${id}`).check()
    await expect(page.getByTestId("bulk-count")).toContainText("1")

    await page.getByTestId("bulk-vat").fill("7")
    await page.getByTestId("bulk-apply").click()

    await expect(page.getByTestId("bulk-bar")).toHaveCount(0)
    await expect
      .poll(async () => appEval(`Expense.find_by(description: "Tricorder").vat_percent`))
      .toBe(7)
  })

  test("deletes the rows that were picked once the confirm is accepted", async ({ page }) => {
    await page.goto("/app/expenses")

    const id = (await appEval(`Expense.find_by(description: "Tricorder").id`)) as string

    page.on("dialog", (dialog) => dialog.accept())
    await page.getByTestId(`select-${id}`).check()
    await page.getByTestId("bulk-delete").click()

    await expect(page.getByTestId("expenses")).not.toContainText("Tricorder")
    await expect.poll(async () => appEval(`Expense.where(description: "Tricorder").count`)).toBe(0)
  })

  // The list is an account feature, and the navigation only offers it where
  // the account has it.
  test("offers the navigation entry only with the feature on", async ({ page }) => {
    await page.goto("/app/")
    await expect(page.getByTestId("nav-expenses")).toBeVisible()

    await appEval(`Account.find_by(name: "Enterprise").update_columns(feature_expenses: false)`)
    await page.reload()

    await expect(page.getByTestId("nav-expenses")).toHaveCount(0)
  })
})

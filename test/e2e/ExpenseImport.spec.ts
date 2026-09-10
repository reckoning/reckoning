import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The two-step CSV import, which the SPA does in one route: the upload and the
// defaults, then the parsed rows to edit before they are saved.
test.describe("Expense import", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      account.update_columns(feature_expenses: true)
    `)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("reads a bank statement into a preview and imports what is ticked", async ({ page }) => {
    await page.goto("/expenses/import")

    // The columns of an exported CSV, read off the model by the API.
    await expect(page.getByTestId("import-columns")).toContainText("expense_type")

    await page.getByTestId("file").setInputFiles("test/fixtures/files/adac_credit_card.csv")
    await page.getByTestId("expense-type").selectOption("licenses")
    await page.getByTestId("continue").click()

    // The credit row is skipped, so the two debits are what is left.
    const rows = page.locator('[data-test="preview-rows"] tbody tr')
    await expect(rows).toHaveCount(2)
    await expect(page.getByTestId("seller-0")).toHaveValue(/Dnsimple/)

    await page.getByTestId("description-0").fill("Domains")
    await page.getByTestId("include-1").uncheck()
    await page.getByTestId("import").click()

    await expect(page).toHaveURL(/\/expenses$/)
    await expect(page.getByTestId("expenses")).toContainText("Domains")

    expect(await appEval(`Expense.count`)).toBe(1)
    expect(await appEval(`Expense.first.expense_type`)).toBe("licenses")
  })

  test("keeps the credit row when it is told to", async ({ page }) => {
    await page.goto("/expenses/import")

    await page.getByTestId("file").setInputFiles("test/fixtures/files/adac_credit_card.csv")
    await page.getByTestId("skip-credits").uncheck()
    await page.getByTestId("continue").click()

    await expect(page.locator('[data-test="preview-rows"] tbody tr')).toHaveCount(3)
  })

  test("says so when the file yields nothing", async ({ page }) => {
    await page.goto("/expenses/import")

    await page.getByTestId("file").setInputFiles({
      name: "empty.csv",
      mimeType: "text/csv",
      buffer: Buffer.from("\n"),
    })
    await page.getByTestId("continue").click()

    await expect(page.getByTestId("import-errors")).toBeVisible()
    await expect(page.locator('[data-test="preview-rows"]')).toHaveCount(0)
  })

  test("goes back to the upload, and out to the list", async ({ page }) => {
    await page.goto("/expenses/import")

    await page.getByTestId("file").setInputFiles("test/fixtures/files/adac_credit_card.csv")
    await page.getByTestId("continue").click()
    await expect(page.locator('[data-test="preview-rows"]')).toBeVisible()

    await page.getByTestId("back").click()
    await expect(page.getByTestId("file")).toBeVisible()

    await page.getByTestId("back").click()
    await expect(page).toHaveURL(/\/expenses$/)
  })

  test("is reachable from the list, filters and all", async ({ page }) => {
    await page.goto("/expenses?type=licenses")

    await page.getByTestId("import").click()

    await expect(page).toHaveURL(/\/expenses\/import\?type=licenses$/)

    // And back out again to the same filtered list.
    await page.getByTestId("cancel").click()
    await expect(page).toHaveURL(/\/expenses\?type=licenses$/)
  })

  test("forwards the old rails path to the spa", async ({ page }) => {
    await page.goto("/expense_imports/new?year=2025")

    await expect(page).toHaveURL(/\/expenses\/import\?year=2025$/)
    await expect(page.getByTestId("import-title")).toBeVisible()
  })
})

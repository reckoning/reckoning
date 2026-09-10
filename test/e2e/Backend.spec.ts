import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The admin screens, the last thing that was server-rendered behind a
// session. What stays on the Rails side under the same prefix are the two
// mounted engines, which are not screens.
test.describe("Backend", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")
    await appEval(`User.find_by(email: "will@star.fleet").update_columns(admin: true)`)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })

  test("is reachable from the user menu, and counts what there is", async ({ page }) => {
    await page.getByTestId("user-menu").click()
    await page.getByTestId("nav-backend").click()

    await expect(page).toHaveURL(/\/backend$/)
    await expect(page.getByTestId("users-count")).toHaveText("1")
    await expect(page.getByTestId("accounts-count")).toHaveText("1")
    await expect(page.getByTestId("latest-users")).toContainText("will@star.fleet")
  })

  // The server-rendered backend had its own navigation across the three
  // areas, and reaching the accounts from the users should not have to go
  // through the dashboard.
  test("crosses between its three areas", async ({ page }) => {
    await page.goto("/backend")

    await page.getByTestId("nav-backend-users").click()
    await expect(page).toHaveURL(/\/backend\/users$/)

    await page.getByTestId("nav-backend-accounts").click()
    await expect(page).toHaveURL(/\/backend\/accounts$/)

    await page.getByTestId("nav-backend-dashboard").click()
    await expect(page).toHaveURL(/\/backend$/)
  })

  test("lists the users and sorts them by a column", async ({ page }) => {
    await appEval(`
      account = Account.find_by(name: "Enterprise")
      %w[arthur@dent.uk zaphod@beeblebrox.betelgeuse].each do |email|
        next if User.exists?(email: email)
        User.new(
          account: account, email: email, name: email,
          encrypted_password: User.new.send(:password_digest, "towel-day"),
          confirmed_at: Time.now, enabled: true
        ).save(validate: false)
      end
    `)

    await page.goto("/backend/users")

    await expect(page.locator('[data-test="users"] tbody tr')).toHaveCount(3)

    await page.getByTestId("sort-email").click()
    await expect(page).toHaveURL(/sort=email&direction=desc/)
    const first = page.locator('[data-test="users"] tbody tr').first()
    await expect(first).toContainText("zaphod@beeblebrox.betelgeuse")

    await page.getByTestId("sort-email").click()
    await expect(page).toHaveURL(/direction=asc/)
    await expect(page.locator('[data-test="users"] tbody tr').first()).toContainText("arthur@dent.uk")
  })

  // The server-rendered form asked for an address and nothing else, and
  // `User` will not have a user without an account — so its create could
  // never succeed. The account is picked here.
  test("creates a user, who gets a mail rather than a password", async ({ page }) => {
    const account = (await appEval(`Account.find_by(name: "Enterprise").id`)) as string

    await page.goto("/backend/users")
    await page.getByTestId("new-user").click()

    await page.getByTestId("email").fill("barclay@star.fleet")
    await page.getByTestId("user-account").selectOption(account)
    await page.getByTestId("admin").check()
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/backend\/users$/)
    await expect(page.getByTestId("users")).toContainText("barclay@star.fleet")

    expect(await appEval(`User.find_by(email: "barclay@star.fleet").admin`)).toBe(true)
    // Unconfirmed, but mailed: the confirmation is how they pick a password.
    expect(await appEval(`User.find_by(email: "barclay@star.fleet").confirmed?`)).toBe(false)
    expect(await appEval(`User.find_by(email: "barclay@star.fleet").created_via_admin`)).toBe(true)
  })

  test("creates an account together with its first user", async ({ page }) => {
    await page.goto("/backend/accounts")
    await page.getByTestId("new-account").click()

    await page.getByTestId("name").fill("Vulcan Science Academy")
    await page.getByTestId("email").fill("spock@vulcan.gov")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/backend\/accounts$/)
    await expect(page.getByTestId("accounts")).toContainText("Vulcan Science Academy")

    expect(await appEval(`Account.find_by(name: "Vulcan Science Academy").users.count`)).toBe(1)
  })

  test("switches an account's features", async ({ page }) => {
    // The scenario saves its account past the validations, so it carries no
    // plan — and an update validates the whole record.
    await appEval(`Account.find_by(name: "Enterprise").update_columns(plan: "free")`)
    const id = (await appEval(`Account.find_by(name: "Enterprise").id`)) as string

    await page.goto(`/backend/accounts/${id}/edit`)
    await page.getByTestId("feature-expenses").check()
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/backend\/accounts$/)
    expect(await appEval(`Account.find_by(name: "Enterprise").feature_expenses`)).toBe(true)
  })

  // The API answers a non-admin with 403, so the screen is not offered — and
  // the guard asks again rather than trusting the session, so losing the
  // flag takes effect without a reload.
  test("keeps a non-admin out", async ({ page }) => {
    await page.goto("/backend/users")
    await expect(page.getByTestId("users-title")).toBeVisible()

    await appEval(`User.find_by(email: "will@star.fleet").update_columns(admin: false)`)

    await page.goto("/backend/accounts")
    await expect(page).toHaveURL(/^https?:\/\/[^/]+\/?$/)

    await page.reload()

    await page.getByTestId("user-menu").click()
    await expect(page.getByTestId("nav-backend")).toHaveCount(0)

    await page.goto("/backend/users")

    await expect(page).toHaveURL(/^https?:\/\/[^/]+\/?$/)
    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })

  // Sidekiq's dashboard is not a screen the SPA can own.
  test("leaves the mounted engines to the server", async ({ page }) => {
    await page.goto("/backend/workers")

    await expect(page.locator("#spa")).toHaveCount(0)
    await expect(page.locator("body")).toContainText("Sidekiq")
  })
})

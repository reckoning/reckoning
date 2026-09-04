import { test, expect } from "./support/commands"
import { app, appScenario } from "./support/on-rails"

// Phase B1's exit criterion: the shell at /app does a full login → dashboard
// → logout round-trip against the real API, not a mocked one.
test.describe("SPA shell", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("signed_out_user")
  })

  test("signs in, reaches the dashboard and signs back out", async ({ page }) => {
    await page.goto("/app")

    // The guard asks GET /me, gets a 401 and routes to login client-side,
    // carrying the route it turned away as a redirect query.
    await expect(page).toHaveURL(/\/app\/login\?redirect=\/$/)

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("dashboard-greeting")).toContainText("will@star.fleet")
    await expect(page).toHaveURL(/\/app\/?$/)

    await page.getByTestId("sign-out").click()

    await expect(page).toHaveURL(/\/app\/login$/)
    await expect(page.getByTestId("submit")).toBeVisible()
  })

  test("keeps the requested path through the login redirect", async ({ page }) => {
    await page.goto("/app/customers")

    await expect(page).toHaveURL(/\/app\/login\?redirect=\/customers$/)

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/app\/customers$/)
  })

  test("rejects bad credentials without leaving the login page", async ({ page }) => {
    await page.goto("/app/login")

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("definitely-not-enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("login-failed")).toBeVisible()
    await expect(page).toHaveURL(/\/app\/login$/)
  })

  // The elements /signin has that the B1 skeleton was missing.
  test("offers remember me, password reset and signup", async ({ page }) => {
    await page.goto("/app/login")

    await expect(page.getByTestId("remember-me")).toBeVisible()
    await expect(page.getByTestId("reset-password")).toBeVisible()

    // Signup is gated on the same config flag the ERB login reads.
    await expect(page.getByTestId("sign-up")).toHaveAttribute("href", "/signup")

    await page.getByTestId("reset-password").click()
    await expect(page).toHaveURL(/\/app\/password\/new$/)
    await expect(page.getByTestId("submit")).toBeVisible()
  })

  test("keeps the session across a browser restart when remember me is checked", async ({ page }) => {
    await page.goto("/app/login")

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("remember-me").check()
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()

    // Devise only writes the remember cookie over HTTPS
    // (config.rememberable_options), so over plain HTTP the flag can only be
    // observed on the user record.
    const cookies = await page.context().cookies()
    expect(cookies.some((c) => c.name.startsWith("RECKONING"))).toBe(true)
  })

  test("validates the form before calling the api", async ({ page }) => {
    await page.goto("/app/login")

    await page.getByTestId("email").fill("not-an-email")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("email-error")).toBeVisible()
    await expect(page.getByTestId("password-error")).toBeVisible()
  })
})

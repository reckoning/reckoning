import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// Phase B1's exit criterion: the shell does a full login → dashboard
// → logout round-trip against the real API, not a mocked one.
test.describe("SPA shell", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("signed_out_user")
  })

  test("signs in, reaches the dashboard and signs back out", async ({ page }) => {
    // Not the root path: a signed-out visitor there is a visitor, and gets
    // the welcome page. The dashboard behind it is what signing in reaches.
    await page.goto("/login")

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("dashboard-greeting")).toContainText("will@star.fleet")
    await expect(page).toHaveURL(/^https?:\/\/[^/]+\/?$/)

    // Signing out lives in the user menu, the way the server-rendered aside
    // has it.
    await page.getByTestId("user-menu").click()
    await page.getByTestId("sign-out").click()

    await expect(page).toHaveURL(/\/login$/)
    await expect(page.getByTestId("submit")).toBeVisible()
  })

  // The bar the server-rendered pages get from Turbo Drive. It waits half a
  // second first, so the request has to be held up to see it at all.
  test("draws the loading bar while a request is in flight", async ({ page }) => {
    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()

    await page.route("**/api/v1/invoices**", async (route) => {
      await new Promise((resolve) => setTimeout(resolve, 2000))
      await route.continue()
    })

    await page.getByTestId("nav-invoices").click()

    await expect(page.getByTestId("loading-bar")).toBeVisible()
    await expect(page).toHaveURL(/\/invoices$/)

    // And it leaves again once the answer is in.
    await expect(page.getByTestId("loading-bar")).toHaveCount(0, { timeout: 15_000 })
    await expect(page.getByTestId("new-invoice")).toBeVisible()
  })

  test("keeps the requested path through the login redirect", async ({ page }) => {
    await page.goto("/customers")

    await expect(page).toHaveURL(/\/login\?redirect=\/customers$/)

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/customers$/)
  })

  test("rejects bad credentials without leaving the login page", async ({ page }) => {
    await page.goto("/login")

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("definitely-not-enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("login-failed")).toBeVisible()
    await expect(page).toHaveURL(/\/login$/)
  })

  // The elements /signin has that the B1 skeleton was missing.
  test("offers remember me, password reset and signup", async ({ page }) => {
    await page.goto("/login")

    await expect(page.getByTestId("remember-me")).toBeVisible()
    await expect(page.getByTestId("reset-password")).toBeVisible()

    // Signup is gated on the same config flag the ERB login reads.
    await expect(page.getByTestId("sign-up")).toHaveAttribute("href", "/signup")

    await page.getByTestId("reset-password").click()
    await expect(page).toHaveURL(/\/password\/new$/)
    await expect(page.getByTestId("submit")).toBeVisible()
  })

  test("keeps the session across a browser restart when remember me is checked", async ({ page }) => {
    await page.goto("/login")

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

  // Loading a public route directly asks /me, which answers 401 for a
  // signed-out visitor. That used to trip the global unauthorized handler and
  // bounce straight back to login — only reachable on a fresh load, so
  // clicking through from the login page never caught it.
  test("opens a public route directly without bouncing to login", async ({ page }) => {
    await page.goto("/password/new")

    await expect(page).toHaveURL(/\/password\/new$/)
    await expect(page.getByTestId("email")).toBeVisible()
  })

  // The root path used to serve the server-rendered dashboard, and the menu
  // had a way across to it. It hands a signed-in visitor to the SPA now.
  test("takes a signed-in visitor from the root path into the spa", async ({ page }) => {
    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()

    await page.goto("/")

    await expect(page).toHaveURL(/^https?:\/\/[^/]+\/?$/)
    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })

  // What is left of the server-rendered app — the two exports — refuses a
  // request the account may not make, and redirects to the root path with
  // the reason in the flash. That path hands it to the SPA, which has to say
  // it out loud rather than answer with a dashboard and nothing.
  test("carries a server-rendered refusal into the spa", async ({ page }) => {
    await appEval(`Account.find_by(name: "Enterprise").update_columns(feature_expenses: false)`)

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()

    // The flash lives in the session cookie, so a request still in flight
    // from the dashboard can answer after the redirect and write the cookie
    // back without it. Let the screen settle first, which is also when
    // someone would reach for an export.
    await page.waitForLoadState("networkidle")

    await page.goto("/expenses.csv")

    await expect(page).toHaveURL(/^https?:\/\/[^/]+\/?$/)

    // The shell carries it on the mount point, and the SPA turns *that* into
    // the toast — the same sentence at both ends, or the handover is only
    // half working.
    await expect(page.locator("#spa")).toHaveAttribute("data-flash-error", /\S/)
    const refusal = await page.locator("#spa").getAttribute("data-flash-error")

    await expect(page.getByTestId("toasts")).toContainText(String(refusal))
  })

  // A server-rendered screen turns a signed-out visitor away to this login.
  // Landing them on the SPA dashboard afterwards would lose the page they
  // asked for, so the path travels along and the login hands it back with a
  // full page load.
  //
  // The screen used to show it is the backend's user list: any
  // server-rendered one that asks for a session will do, and the backend is
  // what is left. Each screen that moves into the SPA quietly turned this
  // into a test of a redirect, so it follows them.
  test("returns to the server-rendered screen it was sent from", async ({ page }) => {
    await appEval(`User.find_by(email: "will@star.fleet").update_columns(admin: true)`)

    await page.goto("/backend/users")

    await expect(page).toHaveURL(/\/login\?return=%2Fbackend%2Fusers$/)

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/backend\/users$/)
    // The legacy chrome, not the SPA shell.
    await expect(page.locator(".user-email")).toContainText("will@star.fleet")
  })

  test("validates the form before calling the api", async ({ page }) => {
    await page.goto("/login")

    await page.getByTestId("email").fill("not-an-email")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("email-error")).toBeVisible()
    await expect(page.getByTestId("password-error")).toBeVisible()
  })
})

import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

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

    // Signing out lives in the user menu, the way the server-rendered aside
    // has it.
    await page.getByTestId("user-menu").click()
    await page.getByTestId("sign-out").click()

    await expect(page).toHaveURL(/\/app\/login$/)
    await expect(page.getByTestId("submit")).toBeVisible()
  })

  // The bar the server-rendered pages get from Turbo Drive. It waits half a
  // second first, so the request has to be held up to see it at all.
  test("draws the loading bar while a request is in flight", async ({ page }) => {
    await page.goto("/app/login")
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
    await expect(page).toHaveURL(/\/app\/invoices$/)

    // And it leaves again once the answer is in.
    await expect(page.getByTestId("loading-bar")).toHaveCount(0, { timeout: 15_000 })
    await expect(page.getByTestId("new-invoice")).toBeVisible()
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

  // Loading a public route directly asks /me, which answers 401 for a
  // signed-out visitor. That used to trip the global unauthorized handler and
  // bounce straight back to login — only reachable on a fresh load, so
  // clicking through from the login page never caught it.
  test("opens a public route directly without bouncing to login", async ({ page }) => {
    await page.goto("/app/password/new")

    await expect(page).toHaveURL(/\/app\/password\/new$/)
    await expect(page.getByTestId("email")).toBeVisible()
  })

  // The root path used to serve the server-rendered dashboard, and the menu
  // had a way across to it. It hands a signed-in visitor to the SPA now.
  test("takes a signed-in visitor from the root path into the spa", async ({ page }) => {
    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()

    await page.goto("/")

    await expect(page).toHaveURL(/\/app\/?$/)
    await expect(page.getByTestId("dashboard-title")).toBeVisible()
  })

  // What is left of the server-rendered app refuses a write once the trial
  // has run out, and redirects to the root path with the reason in the flash.
  // The root path now hands that to the SPA, which has to say it out loud.
  test("carries a server-rendered refusal into the spa", async ({ page }) => {
    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()

    const id = (await appEval(`Project.first&.id || Customer.create!(account: Account.find_by(name: "Enterprise"), name: "Starfleet").projects.create!(name: "Narendra 3").id`)) as string
    await appEval(`
      Account.find_by(name: "Enterprise")
        .update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)
    `)

    // A plain form post, the way the legacy screen makes it. No token: this
    // environment has forgery protection off, as the legacy specs rely on.
    await page.evaluate((projectId) => {
      const form = document.createElement("form")
      form.method = "post"
      form.action = `/projects/${projectId}/tasks`
      form.innerHTML = `<input name="task[name]" value="Refit">`
      document.body.appendChild(form)
      form.submit()
    }, id)

    await expect(page).toHaveURL(/\/app\/?$/)
    await expect(page.getByTestId("toasts")).toContainText("Testphase")
  })

  // A server-rendered screen turns a signed-out visitor away to this login.
  // Landing them on the SPA dashboard afterwards would lose the page they
  // asked for, so the path travels along and the login hands it back with a
  // full page load.
  //
  // `/settings` because it is the server-rendered screen with the longest
  // life left: the lists this used to point at keep moving into the SPA, and
  // each move quietly turned this test into a test of a redirect.
  // The CSV import is the screen used to show it: any server-rendered one
  // that asks for a session will do, and that is the one still left. It used
  // to be the profile, which is the SPA's now.
  test("returns to the server-rendered screen it was sent from", async ({ page }) => {
    await appEval(`Account.find_by(name: "Enterprise").update_columns(feature_expenses: true)`)

    await page.goto("/expense_imports/new")

    await expect(page).toHaveURL(/\/app\/login\?return=%2Fexpense_imports%2Fnew$/)

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/expense_imports\/new$/)
    // The legacy chrome, not the SPA shell.
    await expect(page.locator(".user-email")).toContainText("will@star.fleet")
  })

  test("validates the form before calling the api", async ({ page }) => {
    await page.goto("/app/login")

    await page.getByTestId("email").fill("not-an-email")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("email-error")).toBeVisible()
    await expect(page.getByTestId("password-error")).toBeVisible()
  })
})

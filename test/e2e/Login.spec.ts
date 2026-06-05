import { test, expect } from "./support/commands"
import { app, appScenario } from "./support/on-rails"

test.describe("Login", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("signed_out_user")
  })

  test("user signs in with valid credentials and lands on the dashboard", async ({ page }) => {
    await page.goto("/signin")

    await page.locator("input[name='user[email]']").fill("will@star.fleet")
    await page.locator("input[name='user[password]']").fill("enterprise")
    await page.getByTestId("submit-login").click()

    // The signed-in chrome renders `.user-email` with the current
    // user's email — defined in app/views/layouts/_user_nav.html.erb.
    await expect(page.locator(".user-email")).toContainText("will@star.fleet")
  })

  test("invalid credentials keep the user on /signin with the Devise alert in the body", async ({ page }) => {
    await page.goto("/signin")

    await page.locator("input[name='user[email]']").fill("will@star.fleet")
    await page.locator("input[name='user[password]']").fill("definitely-not-enterprise")
    await page.getByTestId("submit-login").click()

    // Devise's failure_app re-renders the sign-in form with
    // `flash[:alert]`, which the layout writes onto `<body data-error="…">`.
    // Default locale is :de — see `config/locales/de/devise.yml`
    // (`devise.failure.invalid`).
    await expect(page.locator("body")).toHaveAttribute("data-error", /Ungültige Anmeldedaten/)
    // And we're still on /signin, not redirected to the dashboard.
    await expect(page).toHaveURL(/\/signin$/)
    // KNOWN BUG: the noty `.noty_type__error` toast doesn't appear
    // here because Turbo's response to Devise's 422 fires
    // `turbo:render` but not `turbo:load`, so the
    // `turbo:load → turbolinks:load` shim in
    // app/frontend/entrypoints/application.ts never re-runs
    // `helpers/noty.coffee`'s flash reader. Tracked as a Phase 9
    // follow-up — fix is to extend the shim to also handle
    // `turbo:render` once the noty flash handler can de-dupe.
  })
})

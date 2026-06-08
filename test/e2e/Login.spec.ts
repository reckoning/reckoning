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

  test("invalid credentials surface a noty error toast", async ({ page, notification }) => {
    await page.goto("/signin")

    await page.locator("input[name='user[email]']").fill("will@star.fleet")
    await page.locator("input[name='user[password]']").fill("definitely-not-enterprise")
    await page.getByTestId("submit-login").click()

    // Devise's `recall` re-renders the sign-in form with
    // `flash.now[:alert]` (status 422 once `Devise.responder.error_status`
    // is set to `:unprocessable_entity`, see
    // `config/initializers/devise.rb`). The layout writes the alert
    // onto `<body data-error="…">`. The shim in
    // `app/frontend/entrypoints/application.ts` re-fires
    // `turbolinks:load` after Turbo's `turbo:render` (which is the
    // event that fires for form-error responses, not `turbo:load`).
    // `helpers/noty.coffee` then reads the body attr and shows the
    // toast. Default locale is :de — see `config/locales/de/devise.yml`
    // (`devise.failure.invalid`).
    await notification.error("Ungültige Anmeldedaten.")
  })
})

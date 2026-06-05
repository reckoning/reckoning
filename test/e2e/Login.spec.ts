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

    // Devise's failure_app re-renders the sign-in form with
    // `flash[:alert]`, which the layout writes onto `<body data-error="…">`
    // and helpers/noty.coffee shows as a `.noty_type__error` toast.
    await notification.error("Invalid Email or password.")
  })
})

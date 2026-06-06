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

  test("invalid credentials surface a noty error toast", async ({ page, notification }, testInfo) => {
    // Direct POST: bypass the form so we can inspect the raw
    // response Devise returns to a Turbo-style submission.
    // This isolates "did Devise set the flash" from "did Turbo +
    // noty render the toast".
    await page.goto("/signin")
    const csrf = await page.locator("meta[name='csrf-token']").getAttribute("content")
    const directResponse = await page.request.post("/signin", {
      headers: {
        Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "X-CSRF-Token": csrf ?? "",
      },
      form: {
        authenticity_token: csrf ?? "",
        "user[email]": "will@star.fleet",
        "user[password]": "definitely-not-enterprise",
      },
    })
    const status = directResponse.status()
    const body = await directResponse.text()
    const dataErrorMatch = body.match(/data-error="([^"]*)"/)
    const flashTitle = body.match(/<title>([^<]*)</)?.[1] ?? ""
    await testInfo.attach("direct-post-response", {
      body: `status: ${status}\ntitle: ${flashTitle}\ndata-error: ${dataErrorMatch?.[1] ?? "(none)"}\nbody[0..2000]:\n${body.slice(0, 2000)}`,
      contentType: "text/plain",
    })
    expect(status, `direct POST status (response title=${flashTitle})`).toBeLessThan(500)
    expect(dataErrorMatch?.[1], "data-error from direct POST response").toMatch(/Ungültige Anmeldedaten/)

    // Now the actual UI flow.
    await page.locator("input[name='user[email]']").fill("will@star.fleet")
    await page.locator("input[name='user[password]']").fill("definitely-not-enterprise")
    await page.getByTestId("submit-login").click()

    // Devise's failure_app re-renders the sign-in form with
    // `flash[:alert]`, which the layout writes onto
    // `<body data-error="…">`. The shim in
    // `app/frontend/entrypoints/application.ts` listens to
    // `turbo:render` (not just `turbo:load`) so the noty handler
    // re-runs after the form-error response. Default locale is :de —
    // see `config/locales/de/devise.yml` (`devise.failure.invalid`).
    await expect(page).toHaveURL(/\/signin$/)
    await expect(page.locator("body")).toHaveAttribute("data-error", /Ungültige Anmeldedaten/)
    await notification.error("Ungültige Anmeldedaten.")
  })
})

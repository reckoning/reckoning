import { test, expect } from "./support/commands"
import { app, appScenario } from "./support/on-rails"

// The 2FA screen the plan calls for in B2. Enabling for real needs a valid TOTP
// code, which a browser test cannot produce — so this covers enrollment and the
// rejection path, and leaves code generation to the API's own tests.
test.describe("Two-factor settings", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("offers enrollment with a qr code and a provisioning uri", async ({ page }) => {
    await page.getByTestId("nav-two-factor").click()

    await expect(page).toHaveURL(/\/app\/settings\/two-factor$/)
    await expect(page.getByTestId("two-factor-title")).toBeVisible()

    // POST /me/otp on mount generates the secret the URI encodes.
    await expect(page.getByTestId("provisioning-uri")).toContainText("otpauth://")
    await expect(page.getByTestId("otp-qrcode")).toBeVisible()
  })

  test("serves the qr code as an svg", async ({ page }) => {
    await page.goto("/app/settings/two-factor")
    await expect(page.getByTestId("provisioning-uri")).toBeVisible()

    const response = await page.request.get("/api/v1/me/otp/qrcode")

    expect(response.status()).toBe(200)
    expect(response.headers()["content-type"]).toContain("image/svg+xml")
  })

  test("rejects a token the authenticator did not produce", async ({ page }) => {
    await page.goto("/app/settings/two-factor")
    await expect(page.getByTestId("provisioning-uri")).toBeVisible()

    await page.getByTestId("otp-token").fill("000000")
    await page.getByTestId("enable-otp").click()

    await expect(page.getByTestId("two-factor-failed")).toBeVisible()
    // Still on the enrollment side, not the enabled one.
    await expect(page.getByTestId("enable-otp")).toBeVisible()
  })
})

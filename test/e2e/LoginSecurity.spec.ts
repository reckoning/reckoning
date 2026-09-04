import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The gate B2 has to clear before the ERB auth views can go: 2FA and the
// lockout have to hold on the SPA login, not just on /signin.
test.describe("SPA login security", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("signed_out_user")
  })

  test("requires the totp code once 2FA is on", async ({ page }) => {
    await appEval(`
      user = User.find_by(email: "will@star.fleet")
      user.otp_secret = User.generate_otp_secret
      user.otp_required_for_login = true
      user.save(validate: false)
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("login-failed")).toBeVisible()

    // The secret is encrypted at rest, so a current code can only come from
    // the live process.
    const code = (await appEval(`User.find_by(email: "will@star.fleet").current_otp`)) as string

    await page.getByTestId("otp-token").fill(code)
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  // The one path back in for someone who lost their authenticator, and the
  // codes the settings screen hands out are worthless without it.
  test("takes a backup code in the same field", async ({ page }) => {
    const code = (await appEval(`
      user = User.find_by(email: "will@star.fleet")
      user.otp_secret = User.generate_otp_secret
      user.otp_required_for_login = true
      codes = user.generate_otp_backup_codes!
      user.save(validate: false)
      codes.first
    `)) as string

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("otp-token").fill(code)
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("locks the account when the attempts run out", async ({ page }) => {
    // Set one short of the limit so the form drives the attempt that locks it,
    // rather than the spec repeating a round-trip twenty times.
    await appEval(`
      User.find_by(email: "will@star.fleet")
        .update_columns(failed_attempts: User.maximum_attempts - 1)
    `)

    await page.goto("/app/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("definitely-not-enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("login-failed")).toBeVisible()

    const locked = await appEval(`User.find_by(email: "will@star.fleet").access_locked?`)
    expect(locked).toBe(true)

    // And from here the right password gets nowhere either — the unlock email
    // is the only way back in.
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("login-failed")).toBeVisible()
    await expect(page).toHaveURL(/\/app\/login/)
  })
})

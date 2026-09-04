import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The two screens B2 cannot delete the ERB auth views without: both are reached
// from a link in an email, and a locked account has no other way back in.
test.describe("Confirmation and unlock", () => {
  test.beforeEach(async () => {
    await app("clean")
    await appScenario("signed_out_user")
  })

  test("confirms an address from the emailed token", async ({ page }) => {
    // Only the digest is stored, so the raw token has to come from the call
    // that generates it.
    const token = (await appEval(`
      user = User.new(
        account: Account.find_by(name: "Enterprise"),
        name: "Reginald Barclay",
        email: "barclay@star.fleet",
        password: "enterprise",
        password_confirmation: "enterprise"
      )
      user.save(validate: false)
      user.confirmation_token
    `)) as string

    await page.goto(`/app/confirmation?confirmation_token=${token}`)

    await expect(page.getByTestId("confirmation-message")).toBeVisible()

    const confirmed = await appEval(`User.find_by(email: "barclay@star.fleet").confirmed?`)
    expect(confirmed).toBe(true)
  })

  test("rejects a confirmation token that was never issued", async ({ page }) => {
    await page.goto("/app/confirmation?confirmation_token=not-a-real-token")

    await expect(page.getByTestId("confirmation-failed")).toBeVisible()
    // Falls back to the resend form rather than dead-ending.
    await expect(page.getByTestId("email")).toBeVisible()
  })

  test("unlocks an account from the emailed token", async ({ page }) => {
    const token = (await appEval(`
      user = User.find_by(email: "will@star.fleet")
      user.lock_access!(send_instructions: false)
      user.send_unlock_instructions
    `)) as string

    await page.goto(`/app/unlock?unlock_token=${token}`)

    await expect(page.getByTestId("unlock-message")).toBeVisible()

    const locked = await appEval(`User.find_by(email: "will@star.fleet").access_locked?`)
    expect(locked).toBe(false)
  })

  test("offers a fresh unlock email when the link has expired", async ({ page }) => {
    await page.goto("/app/unlock?unlock_token=stale")

    await expect(page.getByTestId("unlock-failed")).toBeVisible()

    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("submit").click()

    // Paranoid endpoint: the same message either way, so assert it responded
    // rather than what it revealed.
    await expect(page.getByTestId("unlock-message")).toBeVisible()
  })
})

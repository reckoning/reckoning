import { test, expect } from "./support/commands"
import { app, appScenario, appEval } from "./support/on-rails"

// The signed-in user's own settings: name, the two email addresses, and the
// way through to two-factor and to a password change.
test.describe("Profile settings", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean")
    await appScenario("signed_out_user")

    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("enterprise")
    await page.getByTestId("submit").click()
    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("saves the name", async ({ page }) => {
    await page.goto("/settings")

    await expect(page.getByTestId("name")).toHaveValue("Will Riker")

    await page.getByTestId("name").fill("William T. Riker")
    await page.getByTestId("submit-basic").click()

    await expect.poll(async () => appEval(`User.first.name`)).toBe("William T. Riker")
  })

  // The address the avatar is looked up under is not necessarily the one you
  // sign in with.
  test("saves the gravatar address beside the login one", async ({ page }) => {
    await page.goto("/settings#security")

    await page.getByTestId("gravatar").fill("riker@star.fleet")
    await page.getByTestId("submit-security").click()

    await expect.poll(async () => appEval(`User.first.gravatar`)).toBe("riker@star.fleet")
  })

  test("says whether two-factor is on and leads to it", async ({ page }) => {
    await page.goto("/settings#security")

    await expect(page.getByTestId("two-factor-state")).toBeVisible()

    await page.getByTestId("two-factor").click()

    await expect(page).toHaveURL(/\/settings\/two-factor$/)
    await expect(page.getByTestId("two-factor-title")).toBeVisible()
  })

  test("changes the password and lets the new one sign in", async ({ page }) => {
    await page.goto("/settings#security")
    await page.getByTestId("change-password").click()

    await expect(page).toHaveURL(/\/settings\/password$/)

    await page.getByTestId("current-password").fill("enterprise")
    await page.getByTestId("password").fill("warpcore9")
    await page.getByTestId("password-confirmation").fill("warpcore9")
    await page.getByTestId("submit").click()

    await expect(page).toHaveURL(/\/settings/)
    await expect
      .poll(async () => appEval(`User.first.valid_password?("warpcore9")`))
      .toBe(true)

    // The session survives a password change, and the router keeps someone
    // signed in off the login screen — so the proof needs a fresh one.
    await page.context().clearCookies()
    await page.goto("/login")
    await page.getByTestId("email").fill("will@star.fleet")
    await page.getByTestId("password").fill("warpcore9")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("dashboard-greeting")).toBeVisible()
  })

  test("says so when the current password was wrong", async ({ page }) => {
    await page.goto("/settings/password")

    await page.getByTestId("current-password").fill("not-the-one")
    await page.getByTestId("password").fill("warpcore9")
    await page.getByTestId("password-confirmation").fill("warpcore9")
    await page.getByTestId("submit").click()

    await expect(page.getByTestId("refused")).toBeVisible()
    await expect(page).toHaveURL(/\/settings\/password$/)
  })

  // The paths the server-rendered screens and Devise's mails link.
  test("forwards the old rails paths to the spa", async ({ page }) => {
    await page.goto("/settings")
    await expect(page).toHaveURL(/\/settings$/)

    await page.goto("/password/edit")
    await expect(page).toHaveURL(/\/settings\/password$/)

    await page.goto("/me/otp")
    await expect(page).toHaveURL(/\/settings\/two-factor$/)
  })

  test("is reachable from the user menu", async ({ page }) => {
    await page.goto("/")

    await page.getByTestId("user-menu").click()
    await page.getByTestId("nav-profile").click()

    await expect(page).toHaveURL(/\/settings$/)
    await expect(page.getByTestId("name")).toBeVisible()
  })
})

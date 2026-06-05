import { test as base } from "@playwright/test"

import Notification from "./commands/notification"
import Confirm from "./commands/confirm"

// Per-spec fixtures. Inject in a test with the destructure:
//
//     test("…", async ({ page, notification, confirm }) => { … })
//
// New helpers should land here as their own class under
// ./commands/<name>.ts and a corresponding entry below.
export const test = base.extend<{
  notification: Notification
  confirm: Confirm
}>({
  notification: async ({ page }, use) => {
    await use(new Notification(page))
  },
  confirm: async ({ page }, use) => {
    await use(new Confirm(page))
  },
})

export { expect } from "@playwright/test"

import { request } from "@playwright/test"
import config from "../../../playwright.config"

// Talks to the cypress-on-rails middleware (initialized in
// config/initializers/cypress_on_rails.rb). The middleware accepts
// POSTs and dispatches to ruby files under test/e2e/app_commands/.
const contextPromise = request.newContext({
  baseURL: config.use?.baseURL ?? "http://localhost:8270",
})

interface CommandPayload {
  name: string
  options?: unknown
}

const appCommands = async (data: CommandPayload | CommandPayload[]): Promise<unknown[]> => {
  const context = await contextPromise
  const response = await context.post("/__e2e__/command", { data })

  if (!response.ok()) {
    const body = await response.text()
    throw new Error(`/__e2e__/command failed with status ${response.status()}: ${body}`)
  }
  return response.json()
}

export const app = (name: string, options: unknown = {}): Promise<unknown> =>
  appCommands({ name, options }).then((body) => body[0])

// Seed a named test fixture defined under
// test/e2e/app_commands/scenarios/<name>.rb.
export const appScenario = (name: string, options: unknown = {}): Promise<unknown> =>
  app(`scenarios/${name}`, options)

// Run arbitrary Ruby against the live Rails process. Use sparingly
// — prefer a named scenario for anything non-trivial.
export const appEval = (code: string): Promise<unknown> => app("eval", code)

export { appCommands }

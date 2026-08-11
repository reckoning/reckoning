import { describe, it, expect, beforeEach, afterEach } from "vitest"
import { setActivePinia, createPinia } from "pinia"
import type { AxiosAdapter } from "axios"
import { AXIOS_INSTANCE } from "@/services/axiosClient"
import { router } from "@/plugins/router"
import type { CurrentUser } from "@/services/api/models"

const user: CurrentUser = {
  id: "b8f1c1f4-0000-4000-8000-000000000001",
  email: "data@enterprise.example",
  accountId: "b8f1c1f4-0000-4000-8000-000000000002",
  createdAt: "2026-08-01T00:00:00Z",
  updatedAt: "2026-08-01T00:00:00Z",
}

const respondWithUser: AxiosAdapter = () =>
  Promise.resolve({
    data: user,
    status: 200,
    statusText: "",
    headers: {},
    config: {} as never,
  })

const respondUnauthorized: AxiosAdapter = () => Promise.reject(new Error("401"))

// The store caches its answer after the first /me, and the reset navigation
// below already spends it — so each case installs its transport against a
// pinia that has not resolved yet.
function startSession(adapter: AxiosAdapter) {
  localStorage.clear()
  setActivePinia(createPinia())
  AXIOS_INSTANCE.defaults.adapter = adapter
}

describe("router guard", () => {
  beforeEach(async () => {
    startSession(respondUnauthorized)
    await router.replace("/login")
    await router.isReady()
  })

  afterEach(() => {
    AXIOS_INSTANCE.defaults.adapter = undefined
  })

  it("sends an anonymous visitor from a guarded route to login", async () => {
    startSession(respondUnauthorized)

    await router.push("/")

    expect(router.currentRoute.value.name).toBe("login")
  })

  // Without this the visitor lands on the dashboard after signing in and loses
  // wherever they were actually headed.
  it("remembers the guarded path as a redirect query", async () => {
    startSession(respondUnauthorized)

    await router.push("/customers")

    expect(router.currentRoute.value.query.redirect).toBe("/customers")
  })

  it("lets a signed-in visitor reach a guarded route", async () => {
    startSession(respondWithUser)

    await router.push("/")

    expect(router.currentRoute.value.name).toBe("dashboard")
  })

  it("keeps a signed-in visitor off the login page", async () => {
    startSession(respondWithUser)
    // Navigating from /login to /login is a no-op, so the guard would never
    // run: start from the route a signed-in visitor would actually be on.
    await router.push("/")

    await router.push("/login")

    expect(router.currentRoute.value.name).toBe("dashboard")
  })
})

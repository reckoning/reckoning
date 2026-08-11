import { describe, it, expect, beforeEach, afterEach } from "vitest"
import { setActivePinia, createPinia } from "pinia"
import type { AxiosAdapter } from "axios"
import { AXIOS_INSTANCE } from "@/services/axiosClient"
import { useCurrentUserStore } from "@/stores/currentUser"
import type { CurrentUser } from "@/services/api/models"

const user: CurrentUser = {
  id: "b8f1c1f4-0000-4000-8000-000000000001",
  email: "data@enterprise.example",
  accountId: "b8f1c1f4-0000-4000-8000-000000000002",
  createdAt: "2026-08-01T00:00:00Z",
  updatedAt: "2026-08-01T00:00:00Z",
}

// Swap only the transport so the mutator and the generated service stay on the
// real code path.
function stubTransport(respond: AxiosAdapter) {
  AXIOS_INSTANCE.defaults.adapter = respond
}

function jsonResponse(data: unknown, status = 200): ReturnType<AxiosAdapter> {
  return Promise.resolve({
    data,
    status,
    statusText: "",
    headers: {},
    config: {} as never,
  })
}

describe("useCurrentUserStore", () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
  })

  afterEach(() => {
    AXIOS_INSTANCE.defaults.adapter = undefined
  })

  it("hydrates from GET /me", async () => {
    stubTransport(() => jsonResponse(user))

    const store = useCurrentUserStore()
    await store.load()

    expect(store.signedIn).toBe(true)
    expect(store.user?.email).toBe(user.email)
  })

  it("treats a rejected /me as signed out rather than throwing", async () => {
    stubTransport(() => Promise.reject(new Error("401")))

    const store = useCurrentUserStore()
    await store.load()

    expect(store.signedIn).toBe(false)
    expect(store.resolved).toBe(true)
  })

  // The guard runs per navigation; three redirects on a cold load must not
  // become three identical requests.
  it("coalesces concurrent loads into one request", async () => {
    let calls = 0
    stubTransport(() => {
      calls += 1
      return jsonResponse(user)
    })

    const store = useCurrentUserStore()
    await Promise.all([store.load(), store.load(), store.load()])

    expect(calls).toBe(1)
  })

  it("does not re-request once resolved", async () => {
    let calls = 0
    stubTransport(() => {
      calls += 1
      return jsonResponse(user)
    })

    const store = useCurrentUserStore()
    await store.load()
    await store.load()

    expect(calls).toBe(1)
  })

  // Signing in reuses a store that has already answered "signed out" for the
  // guard, so refresh has to ask again instead of replaying that answer.
  it("re-requests /me on refresh even after resolving", async () => {
    stubTransport(() => Promise.reject(new Error("401")))

    const store = useCurrentUserStore()
    await store.load()
    expect(store.signedIn).toBe(false)

    stubTransport(() => jsonResponse(user))
    await store.refresh()

    expect(store.signedIn).toBe(true)
    expect(store.user?.email).toBe(user.email)
  })

  it("clears the user on sign out even when the request fails", async () => {
    stubTransport(() => jsonResponse(user))

    const store = useCurrentUserStore()
    await store.load()

    stubTransport(() => Promise.reject(new Error("boom")))
    await expect(store.signOut()).rejects.toThrow()

    expect(store.signedIn).toBe(false)
  })
})

import { describe, it, expect, beforeEach, afterEach } from "vitest"
import type { AxiosAdapter, InternalAxiosRequestConfig } from "axios"
import {
  AXIOS_INSTANCE,
  axiosClient,
  onUnauthorized,
  withoutUnauthorizedRedirect,
} from "@/services/axiosClient"

function captureRequest(): { config: () => InternalAxiosRequestConfig | undefined } {
  let seen: InternalAxiosRequestConfig | undefined

  AXIOS_INSTANCE.defaults.adapter = ((config: InternalAxiosRequestConfig) => {
    seen = config
    return Promise.resolve({
      data: {},
      status: 200,
      statusText: "",
      headers: {},
      config,
    })
  }) as AxiosAdapter

  return { config: () => seen }
}

function setCsrfMeta(token: string | undefined) {
  document.head.querySelector('meta[name="csrf-token"]')?.remove()

  if (token === undefined) return

  const meta = document.createElement("meta")
  meta.setAttribute("name", "csrf-token")
  meta.setAttribute("content", token)
  document.head.appendChild(meta)
}

describe("axiosClient", () => {
  beforeEach(() => {
    setCsrfMeta("token-from-the-layout")
  })

  afterEach(() => {
    AXIOS_INSTANCE.defaults.adapter = undefined
    setCsrfMeta(undefined)
    onUnauthorized(() => {})
  })

  // Api::BaseController raises InvalidAuthenticityToken without this.
  it("sends the layout's CSRF token on mutations", async () => {
    const request = captureRequest()

    await axiosClient({ url: "/customers", method: "POST", data: {} })

    expect(request.config()?.headers["X-CSRF-Token"]).toBe("token-from-the-layout")
  })

  it("omits the token on safe methods", async () => {
    const request = captureRequest()

    await axiosClient({ url: "/customers", method: "GET" })

    expect(request.config()?.headers["X-CSRF-Token"]).toBeUndefined()
  })

  it("does not invent a token when the layout rendered none", async () => {
    setCsrfMeta(undefined)
    const request = captureRequest()

    await axiosClient({ url: "/customers", method: "POST", data: {} })

    expect(request.config()?.headers["X-CSRF-Token"]).toBeUndefined()
  })

  // An expired session otherwise surfaces as a bare error on whichever screen
  // happened to be open.
  it("notifies the unauthorized handler on a 401", async () => {
    let notified = 0
    onUnauthorized(() => {
      notified += 1
    })

    AXIOS_INSTANCE.defaults.adapter = (() =>
      Promise.reject(
        Object.assign(new Error("unauthorized"), {
          isAxiosError: true,
          response: { status: 401, data: {}, statusText: "", headers: {}, config: {} },
        }),
      )) as AxiosAdapter

    await expect(axiosClient({ url: "/me", method: "GET" })).rejects.toThrow()

    expect(notified).toBe(1)
  })

  // Asking "is anyone signed in?" answers 401 for a signed-out visitor. Firing
  // the handler for that bounced every public route — confirmation, unlock,
  // password reset — to the login screen on first load.
  it("stays quiet for a 401 inside withoutUnauthorizedRedirect", async () => {
    let notified = 0
    onUnauthorized(() => {
      notified += 1
    })

    AXIOS_INSTANCE.defaults.adapter = (() =>
      Promise.reject(
        Object.assign(new Error("unauthorized"), {
          isAxiosError: true,
          response: { status: 401, data: {}, statusText: "", headers: {}, config: {} },
        }),
      )) as AxiosAdapter

    await expect(
      withoutUnauthorizedRedirect(() => axiosClient({ url: "/me", method: "GET" })),
    ).rejects.toThrow()

    expect(notified).toBe(0)
  })

  it("resumes notifying once the suppressed call finishes", async () => {
    let notified = 0
    onUnauthorized(() => {
      notified += 1
    })

    AXIOS_INSTANCE.defaults.adapter = (() =>
      Promise.reject(
        Object.assign(new Error("unauthorized"), {
          isAxiosError: true,
          response: { status: 401, data: {}, statusText: "", headers: {}, config: {} },
        }),
      )) as AxiosAdapter

    await expect(
      withoutUnauthorizedRedirect(() => axiosClient({ url: "/me", method: "GET" })),
    ).rejects.toThrow()
    await expect(axiosClient({ url: "/customers", method: "GET" })).rejects.toThrow()

    expect(notified).toBe(1)
  })

  it("leaves other failures to the caller", async () => {
    let notified = 0
    onUnauthorized(() => {
      notified += 1
    })

    AXIOS_INSTANCE.defaults.adapter = (() =>
      Promise.reject(
        Object.assign(new Error("server error"), {
          isAxiosError: true,
          response: { status: 500, data: {}, statusText: "", headers: {}, config: {} },
        }),
      )) as AxiosAdapter

    await expect(axiosClient({ url: "/me", method: "GET" })).rejects.toThrow()

    expect(notified).toBe(0)
  })
})

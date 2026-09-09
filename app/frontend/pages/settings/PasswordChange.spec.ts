import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import PasswordChange from "./PasswordChange.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

async function mountForm(options: {refuse?: boolean} = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    if (options.refuse) throw {response: {status: 400, data: {code: "validation_error.user.password"}}}

    return {data: {}, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/settings", name: "profile-settings", component: {template: "<div />"}},
      {path: "/settings/password", name: "password-change", component: PasswordChange},
    ],
  })
  await router.push("/settings/password")
  await router.isReady()

  const wrapper = mount(PasswordChange, {
    global: {
      plugins: [
        [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
        i18n,
        createPinia(),
        router,
      ],
    },
  })

  await flushPromises()

  return {wrapper, router, requests}
}

async function fill(wrapper: Awaited<ReturnType<typeof mountForm>>["wrapper"], values: {
  current?: string
  password?: string
  confirmation?: string
}) {
  if (values.current !== undefined) {
    await wrapper.get('[data-test="current-password"]').setValue(values.current)
  }
  if (values.password !== undefined) {
    await wrapper.get('[data-test="password"]').setValue(values.password)
  }
  if (values.confirmation !== undefined) {
    await wrapper.get('[data-test="password-confirmation"]').setValue(values.confirmation)
  }
}

describe("PasswordChange", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("sends the three fields devise asks for and returns to the profile", async () => {
    const {wrapper, router, requests} = await mountForm()

    await fill(wrapper, {current: "enterprise", password: "warpcore9", confirmation: "warpcore9"})
    await wrapper.get("form").trigger("submit")

    const body = await vi.waitFor(() => {
      const call = requests.find((entry) => entry.method?.toLowerCase() === "patch")
      expect(call).toBeTruthy()

      return JSON.parse(String(call?.data))
    })

    expect(body).toEqual({
      current_password: "enterprise",
      password: "warpcore9",
      password_confirmation: "warpcore9",
    })

    await vi.waitFor(() => expect(router.currentRoute.value.name).toBe("profile-settings"))
  })

  // Devise's own rules, said here rather than after a round trip.
  it("refuses a new password that is too short", async () => {
    const {wrapper, requests} = await mountForm()

    await fill(wrapper, {current: "enterprise", password: "short", confirmation: "short"})
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() => expect(wrapper.find('[data-test="password-error"]').exists()).toBe(true))

    expect(requests.some((entry) => entry.method?.toLowerCase() === "patch")).toBe(false)
  })

  it("refuses a repeat that does not match", async () => {
    const {wrapper, requests} = await mountForm()

    await fill(wrapper, {current: "enterprise", password: "warpcore9", confirmation: "warpcore8"})
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() =>
      expect(wrapper.find('[data-test="password-confirmation-error"]').exists()).toBe(true),
    )

    expect(requests.some((entry) => entry.method?.toLowerCase() === "patch")).toBe(false)
  })

  it("asks for the current password", async () => {
    const {wrapper} = await mountForm()

    await fill(wrapper, {password: "warpcore9", confirmation: "warpcore9"})
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() =>
      expect(wrapper.find('[data-test="current-password-error"]').exists()).toBe(true),
    )
  })

  // The one thing the form cannot know in advance is whether the current
  // password is right, so it stays put and says so.
  it("stays and says so when the current password was wrong", async () => {
    const {wrapper, router} = await mountForm({refuse: true})

    await fill(wrapper, {current: "wrong", password: "warpcore9", confirmation: "warpcore9"})
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() => expect(wrapper.find('[data-test="refused"]').exists()).toBe(true))

    expect(router.currentRoute.value.name).toBe("password-change")
  })
})

import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import ProfileSettings from "./ProfileSettings.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ME = {
  id: "cccccccc-0000-4000-8000-000000000001",
  email: "will@star.fleet",
  name: "Will Riker",
  gravatar: "will@star.fleet",
  avatar: "https://www.gravatar.com/avatar/abc",
  layout: "default",
  admin: false,
  otpRequired: false,
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

async function mountProfile(path = "/settings", overrides: Record<string, unknown> = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    return {data: {...ME, ...overrides}, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/settings", name: "profile-settings", component: ProfileSettings},
      {path: "/settings/password", name: "password-change", component: {template: "<div />"}},
      {path: "/settings/two-factor", name: "two-factor", component: {template: "<div />"}},
    ],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(ProfileSettings, {
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

async function saved(requests: AxiosRequestConfig[]) {
  return vi.waitFor(() => {
    const call = requests.find((entry) => entry.method?.toLowerCase() === "patch")
    expect(call).toBeTruthy()

    return JSON.parse(String(call?.data))
  })
}

describe("ProfileSettings", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("opens on the first section with the profile filled in", async () => {
    const {wrapper} = await mountProfile()

    expect((wrapper.get('[data-test="name"]').element as HTMLInputElement).value).toBe("Will Riker")
  })

  it("opens the section the hash names", async () => {
    const {wrapper} = await mountProfile("/settings#security")

    expect(wrapper.find('[data-test="section-security"]').exists()).toBe(true)
    expect((wrapper.get('[data-test="email"]').element as HTMLInputElement).value).toBe(
      "will@star.fleet",
    )
  })

  it("saves the name on its own", async () => {
    const {wrapper, requests} = await mountProfile()

    await wrapper.get('[data-test="name"]').setValue("William Riker")
    await wrapper.get("form").trigger("submit")

    expect(await saved(requests)).toEqual({name: "William Riker"})
  })

  // The address the avatar is looked up under is not necessarily the one you
  // sign in with, so both travel together.
  it("saves the email and the gravatar address together", async () => {
    const {wrapper, requests} = await mountProfile("/settings#security")

    await wrapper.get('[data-test="gravatar"]').setValue("riker@star.fleet")
    await wrapper.get("form").trigger("submit")

    expect(await saved(requests)).toEqual({
      email: "will@star.fleet",
      gravatar: "riker@star.fleet",
    })
  })

  // The badge beside the button says whether it is on — green with a tick,
  // red with a cross, and not a control either way.
  it("says whether two-factor is on", async () => {
    const {wrapper} = await mountProfile("/settings#security")

    expect(wrapper.get('[data-test="two-factor-state"]').html()).toContain("fa-close")

    const {wrapper: enabled} = await mountProfile("/settings#security", {otpRequired: true})

    expect(enabled.get('[data-test="two-factor-state"]').html()).toContain("fa-check")
  })

  it("leads to the two-factor screen and to the password change", async () => {
    const {wrapper} = await mountProfile("/settings#security")

    expect(wrapper.find('[data-test="two-factor"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="change-password"]').exists()).toBe(true)
  })
})

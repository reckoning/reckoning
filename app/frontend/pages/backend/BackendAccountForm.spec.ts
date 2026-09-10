import {describe, it, expect, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import BackendAccountForm from "./BackendAccountForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ID = "aaaaaaaa-0000-4000-8000-000000000001"

const ACCOUNT = {
  id: ID,
  name: "Enterprise",
  subdomain: null,
  plan: "basic",
  featureExpenses: false,
  featureLogbook: true,
  usersCount: 3,
  trialEndAt: null,
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

interface Options {
  path?: string
  refuse?: unknown
}

async function mountForm(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    if (config.method !== "get" && options.refuse) throw options.refuse

    return {data: ACCOUNT, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/backend/accounts", name: "backend-accounts", component: {template: "<div />"}},
      {path: "/backend/accounts/new", name: "backend-account-new", component: BackendAccountForm},
      {
        path: "/backend/accounts/:id/edit",
        name: "backend-account-edit",
        component: BackendAccountForm,
      },
    ],
  })

  await router.push(options.path ?? "/backend/accounts/new")
  await router.isReady()

  const wrapper = mount(BackendAccountForm, {
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

describe("BackendAccountForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  // An account is invalid without a user, so creating takes the first one's
  // address with it — and the feature flags belong to an account that exists.
  it("asks for the first user when creating, and nothing else", async () => {
    const {wrapper} = await mountForm()

    expect(wrapper.find('[data-test="email"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="feature-expenses"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="destroy"]').exists()).toBe(false)
  })

  it("sends the name and the address it was given", async () => {
    const {wrapper, requests, router} = await mountForm()

    await wrapper.get('[data-test="name"]').setValue("Vulcan Science Academy")
    await wrapper.get('[data-test="email"]').setValue("spock@vulcan.gov")
    await wrapper.get("form").trigger("submit")
    await flushPromises()

    const created = requests.find((entry) => entry.method === "post")

    expect(JSON.parse(String(created?.data))).toEqual({
      name: "Vulcan Science Academy",
      email: "spock@vulcan.gov",
    })
    expect(router.currentRoute.value.name).toBe("backend-accounts")
  })

  it("switches the features of an account that exists", async () => {
    const {wrapper, requests} = await mountForm({path: `/backend/accounts/${ID}/edit`})

    expect((wrapper.get('[data-test="feature-logbook"]').element as HTMLInputElement).checked).toBe(
      true,
    )
    expect(wrapper.find('[data-test="email"]').exists()).toBe(false)

    await wrapper.get('[data-test="feature-expenses"]').setValue(true)
    await wrapper.get("form").trigger("submit")
    await flushPromises()

    const saved = requests.find((entry) => entry.method === "patch")

    expect(JSON.parse(String(saved?.data))).toEqual({
      name: "Enterprise",
      feature_expenses: true,
      feature_logbook: true,
    })
  })

  // The plan is on the list, not in the form: no server-rendered screen ever
  // offered it, and the codes are records rather than a fixed set.
  it("does not offer the plan", async () => {
    const {wrapper} = await mountForm({path: `/backend/accounts/${ID}/edit`})

    expect(wrapper.find('[data-test="plan"]').exists()).toBe(false)
  })

  it("keeps the form open with what the endpoint refused", async () => {
    const {wrapper, router} = await mountForm({
      refuse: {
        response: {
          status: 400,
          data: {
            code: "validation_error.account.create",
            message: "no",
            errors: {name: ["Bitte füllen Sie das Feld aus"]},
          },
        },
      },
    })

    await wrapper.get('[data-test="email"]').setValue("spock@vulcan.gov")
    await wrapper.get("form").trigger("submit")
    await flushPromises()

    expect(wrapper.get('[data-test="form-errors"]').text()).toContain("Bitte füllen")
    expect(router.currentRoute.value.name).toBe("backend-account-new")
  })
})

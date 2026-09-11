import {describe, it, expect, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import BackendUserForm from "./BackendUserForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ACCOUNTS = [
  {
    id: "aaaaaaaa-0000-4000-8000-000000000001",
    name: "Enterprise",
    subdomain: null,
    plan: "basic",
    featureExpenses: false,
    featureLogbook: false,
    usersCount: 3,
    trialEndAt: null,
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
  },
]

interface Options {
  path?: string
  refuseAccounts?: boolean
}

async function mountForm(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)

    if (url.includes("/accounts") && options.refuseAccounts) {
      throw {response: {status: 500, data: {}}}
    }

    const data = url.includes("/accounts") ? ACCOUNTS : {}

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/backend", name: "backend", component: {template: "<div />"}},
      {path: "/backend/users", name: "backend-users", component: {template: "<div />"}},
      {path: "/backend/accounts", name: "backend-accounts", component: {template: "<div />"}},
      {path: "/backend/users/new", name: "backend-user-new", component: BackendUserForm},
      {path: "/backend/users/:id/edit", name: "backend-user-edit", component: BackendUserForm},
    ],
  })

  await router.push(options.path ?? "/backend/users/new")
  await router.isReady()

  const wrapper = mount(BackendUserForm, {
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

describe("BackendUserForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  // `User` will not have a user without an account, and which one it is
  // cannot be guessed here — so the accounts are part of the form, not a
  // decoration on it.
  it("offers the accounts to pick from", async () => {
    const {wrapper} = await mountForm()

    expect(wrapper.get('[data-test="user-account"]').text()).toContain("Enterprise")
  })

  // Without them the select is empty, and a form that can only submit an
  // account nobody picked is worse than saying the list did not load.
  it("says so when the accounts could not be loaded", async () => {
    const {wrapper} = await mountForm({refuseAccounts: true})

    expect(wrapper.find('[data-test="error"]').exists()).toBe(true)
    expect(wrapper.find("form").exists()).toBe(false)
  })
})

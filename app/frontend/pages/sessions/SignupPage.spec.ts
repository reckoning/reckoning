import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import SignupPage from "./SignupPage.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const PLANS = [
  {
    id: "aaaaaaaa-0000-4000-8000-000000000001",
    code: "basic",
    name: "Basic",
    price: 900,
    quantity: 1,
    interval: "month",
    featured: false,
    descriptions: [],
  },
  {
    id: "aaaaaaaa-0000-4000-8000-000000000002",
    code: "plus",
    name: "Plus",
    price: 1900,
    quantity: 1,
    interval: "month",
    featured: true,
    descriptions: [],
  },
]

interface Options {
  path?: string
  failWith?: {status: number; data: unknown}
}

async function mountPage(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)

    if (url.includes("/registrations")) {
      if (options.failWith) {
        return Promise.reject(
          Object.assign(new Error("rejected"), {
            isAxiosError: true,
            config,
            response: {...options.failWith, statusText: "", headers: {}, config},
          }),
        )
      }

      return {data: {id: "1", name: "Vulcan", createdAt: ""}, status: 201, statusText: "", headers: {}, config}
    }

    const data = url.includes("/plans")
      ? PLANS
      : {registrationEnabled: true, accountName: null, domain: "reckoning.test", version: "1.0.0", codename: "pluto"}

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/", name: "dashboard", component: {template: "<div />"}},
      {path: "/login", name: "login", component: {template: "<div />"}},
      {path: "/signup", name: "signup", component: SignupPage},
    ],
  })

  await router.push(options.path ?? "/signup")
  await router.isReady()

  const wrapper = mount(SignupPage, {
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

async function fillIn(wrapper: Awaited<ReturnType<typeof mountPage>>["wrapper"]) {
  await wrapper.get('[data-test="name"]').setValue("Vulcan Science Academy")
  await wrapper.get('[data-test="email"]').setValue("t.pol@vulcan.gov")
  await wrapper.get('[data-test="password"]').setValue("logic-is-the-beginning")
  await wrapper.get('[data-test="password-confirmation"]').setValue("logic-is-the-beginning")
}

describe("SignupPage", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  it("offers the plans and the host a subdomain would sit under", async () => {
    const {wrapper} = await mountPage()

    expect(wrapper.findAll('[data-test="plan"] option')).toHaveLength(2)
    expect(wrapper.get('[data-test="plan"]').text()).toContain("Basic (9.00 € per month)")
    expect(wrapper.text()).toContain(".reckoning.test")
  })

  // `?plan=` is how the pricing table hands one over.
  it("starts on the plan it was sent to", async () => {
    const {wrapper} = await mountPage({path: "/signup?plan=plus"})

    expect((wrapper.get('[data-test="plan"]').element as HTMLSelectElement).value).toBe("plus")
  })

  // The free plan is not one of the plans on offer, so there is nothing to pick.
  it("hides the select on the free plan", async () => {
    const {wrapper} = await mountPage({path: "/signup?plan=free"})

    expect(wrapper.find('[data-test="plan"]').exists()).toBe(false)
  })

  it("creates the account and sends the visitor to sign in", async () => {
    const {wrapper, router, requests} = await mountPage()

    await fillIn(wrapper)
    await wrapper.get("form").trigger("submit")

    // Validation is async, so the request is a few microtasks behind the
    // submit.
    const created = await vi.waitFor(() => {
      const request = requests.find((entry) => String(entry.url).includes("/registrations"))
      expect(request).toBeTruthy()

      return request
    })

    expect(JSON.parse(String(created?.data))).toMatchObject({
      name: "Vulcan Science Academy",
      plan: "basic",
      users_attributes: [{email: "t.pol@vulcan.gov"}],
    })
    await vi.waitFor(() => expect(router.currentRoute.value.name).toBe("login"))
  })

  it("will not submit a confirmation that does not match", async () => {
    const {wrapper, requests} = await mountPage()

    await fillIn(wrapper)
    await wrapper.get('[data-test="password-confirmation"]').setValue("something-else")
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() => {
      expect(wrapper.get('[data-test="password-confirmation-error"]').text()).toContain(
        "do not match",
      )
    })
    expect(requests.some((request) => String(request.url).includes("/registrations"))).toBe(false)
  })

  // The taken subdomain is the refusal a visitor is most likely to hit, and
  // it belongs on the field rather than in a heap at the bottom.
  it("puts a refusal on the field it belongs to", async () => {
    const {wrapper} = await mountPage({
      failWith: {
        status: 400,
        data: {
          code: "validation_error.account.create",
          message: "Account konnte nicht erstellt werden.",
          errors: {subdomain: ["ist bereits vergeben"], "users.email": ["ist bereits vergeben"]},
        },
      },
    })

    await fillIn(wrapper)
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() => {
      expect(wrapper.get('[data-test="subdomain-error"]').text()).toContain("bereits vergeben")
    })
    expect(wrapper.get('[data-test="email-error"]').text()).toContain("bereits vergeben")
  })
})

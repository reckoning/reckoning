import {describe, it, expect, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import WelcomePage from "./WelcomePage.vue"
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
    descriptions: ["<b>5</b> aktive Projekte", "<b>1</b> Benutzer"],
  },
  {
    id: "aaaaaaaa-0000-4000-8000-000000000002",
    code: "plus",
    name: "Plus",
    price: 1900,
    quantity: 1,
    interval: "month",
    featured: true,
    descriptions: ["<b>&infin;</b> aktive Projekte", "<b>5</b> Benutzer"],
  },
]

// `plans: null` stands for a request that failed rather than one that came
// back empty.
async function mountPage(plans: unknown[] | null = PLANS) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    const url = String(config.url)

    if (url.includes("/plans") && plans === null) {
      return Promise.reject(Object.assign(new Error("boom"), {isAxiosError: true, config}))
    }

    const data = url.includes("/plans")
      ? plans
      : {registrationEnabled: true, accountName: null, domain: "reckoning.test", version: "1.0.0", codename: "pluto"}

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/", name: "dashboard", component: WelcomePage},
      {path: "/login", name: "login", component: {template: "<div />"}},
    ],
  })

  await router.push("/")
  await router.isReady()

  const wrapper = mount(WelcomePage, {
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

  return wrapper
}

describe("WelcomePage", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  it("shows what the page is selling", async () => {
    const wrapper = await mountPage()

    expect(wrapper.get("h1").text()).toContain("Invoicing made simple.")
    expect(wrapper.findAll('[data-test="screenshot"]')).toHaveLength(3)
  })

  it("opens a screenshot and closes it again", async () => {
    const wrapper = await mountPage()

    expect(wrapper.find('[data-test="screenshot-modal"]').exists()).toBe(false)

    await wrapper.findAll('[data-test="screenshot"]')[0].trigger("click")
    expect(wrapper.find('[data-test="screenshot-modal"]').exists()).toBe(true)

    await wrapper.get('[data-test="close-screenshot"]').trigger("click")
    expect(wrapper.find('[data-test="screenshot-modal"]').exists()).toBe(false)
  })

  it("prices the plans the way the pricing table did", async () => {
    const wrapper = await mountPage()

    const plans = wrapper.findAll('[data-test="plan"]')

    expect(plans).toHaveLength(2)
    // Cents from the API, euros on the page, and the interval spelled out.
    expect(plans[0].text()).toContain("9.00")
    expect(plans[0].text()).toContain("per month")
    // The lines are authored with the number in bold.
    expect(plans[0].html()).toContain("<b>5</b> aktive Projekte")
  })

  // `plans.small_print` prices an extra user at what `Plan.base` costs, which
  // is the plan called `basic` — not whichever happens to sort first.
  it("prices an extra user off the base plan", async () => {
    const discounted = [{...PLANS[1], price: 500}, {...PLANS[0], price: 900}]
    const wrapper = await mountPage(discounted)

    expect(wrapper.get('[data-test="small-print"]').text()).toContain("9.00 €")
  })

  // Nothing is on offer until there is a plan to sell.
  it("leaves the pricing out when there are no plans", async () => {
    const wrapper = await mountPage([])

    expect(wrapper.find('[data-test="plans"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="sign-up"]').exists()).toBe(false)
  })

  // A request that failed is not an empty price list: the offer stands, and
  // saying so beats a page that looks complete with nothing to sell.
  it("keeps the offer up when the prices cannot be loaded", async () => {
    const wrapper = await mountPage(null)

    expect(wrapper.find('[data-test="plans"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="plans-failed"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="sign-up"]').exists()).toBe(true)
  })
})

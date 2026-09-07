import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import InvoicesList from "./InvoicesList.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const INVOICE = {
  id: "dddddddd-0000-4000-8000-000000000001",
  ref: 1,
  refNumber: "00001",
  state: "created",
  date: "2026-03-01",
  value: "100.0",
  vat: "19.0",
  customerName: "Starfleet",
  positions: [],
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

const SUMMARY = {count: 2, value: "350.0", vat: "66.5", years: [2026, 2024]}

async function mountList(requests: AxiosRequestConfig[] = [], path = "/invoices", limitReached = false) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    const data = url.includes("summary")
      ? SUMMARY
      : url.includes("/account")
        ? {id: "eeeeeeee-0000-4000-8000-000000000001", name: "Enterprise", invoiceLimitReached: limitReached}
        : [INVOICE]

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/invoices", name: "invoices", component: InvoicesList},
      // The row links at the detail route; where it leads is the router's
      // business, not this component's.
      {path: "/invoices/new", name: "invoice-new", component: {template: "<div />"}},
      {path: "/invoices/:id", name: "invoice", component: {template: "<div />"}},
    ],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(InvoicesList, {
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

  return {wrapper, router}
}

describe("InvoicesList", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("lists what the endpoint returns", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="invoices"]').text()).toContain("Starfleet")
    expect(wrapper.get('[data-test="invoices"]').text()).toContain("00001")
  })

  // The total under a filtered table has to be the total of that table, which
  // is why it comes from its own endpoint rather than from the page.
  it("shows what the filtered set adds up to", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="summary-value"]').text()).toContain("350")
    expect(wrapper.get('[data-test="summary-vat"]').text()).toContain("66")
  })

  it("fills the year filter from the years the account has invoices in", async () => {
    const {wrapper} = await mountList()

    const years = wrapper.get('[data-test="filter-year"]').findAll("option").map((o) => o.text())

    expect(years).toContain("2026")
    expect(years).toContain("2024")
  })

  // The query is the state, so a filtered, sorted page is a link.
  it("puts a filter in the url and asks the endpoint for it", async () => {
    const requests: AxiosRequestConfig[] = []
    const {wrapper, router} = await mountList(requests)

    await wrapper.get('[data-test="filter-state"]').setValue("paid")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.state).toBe("paid")
      expect(requests.some((entry) => entry.params?.state === "paid")).toBe(true)
    })
  })

  it("turns the sort around when the same column is clicked twice", async () => {
    const {wrapper, router} = await mountList()

    await wrapper.get('[data-test="sort-value"]').trigger("click")
    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.direction).toBe("desc")
    })

    await wrapper.get('[data-test="sort-value"]').trigger("click")
    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.direction).toBe("asc")
    })
  })

  it("drops back to the first page when the filter changes", async () => {
    const {wrapper, router} = await mountList([], "/invoices?page=3")

    expect(wrapper.get('[data-test="page"]').text()).toBe("3")

    await wrapper.get('[data-test="filter-state"]').setValue("paid")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.page).toBeUndefined()
    })
  })

  // The API hands over a bare YYYY-MM-DD. Read as UTC midnight and printed
  // in local time, that is the previous day west of Greenwich.
  it("prints the date it was given, in any timezone", async () => {
    const original = process.env.TZ
    process.env.TZ = "America/Los_Angeles"

    try {
      const {wrapper} = await mountList()

      expect(wrapper.get('[data-test="invoices"]').text()).toContain("2026")
      expect(wrapper.get('[data-test="invoices"]').text()).not.toContain("28")
    } finally {
      process.env.TZ = original
    }
  })

  // A demo deployment caps non-admins at two invoices, and the server bounces
  // them back to a list that never renders the flash saying why.
  it("offers no new invoice when the demo limit is reached", async () => {
    const {wrapper} = await mountList([], "/invoices", true)

    expect(wrapper.find('[data-test="new-invoice"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="new-invoice-disabled"]').exists()).toBe(true)
  })

  // A short page means there is nothing after it.
  it("offers no next page when the page came back short", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="next-page"]').attributes("disabled")).toBeDefined()
    expect(wrapper.get('[data-test="prev-page"]').attributes("disabled")).toBeDefined()
  })
})

import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import OffersList from "./OffersList.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const OFFER = {
  id: "cccccccc-0000-4000-8000-000000000001",
  ref: 1,
  refNumber: "00001",
  state: "bided",
  date: "2026-03-01",
  value: "100.0",
  rate: "150.0",
  customerName: "Starfleet",
  projectName: "Narendra III",
  positions: [],
  editable: true,
  abilities: {update: true, destroy: true, transitions: ["bid"]},
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

const SUMMARY = {count: 2, value: "350.0", years: [2026, 2024]}

async function mountList(
  requests: AxiosRequestConfig[] = [],
  path = "/offers",
  summary: Record<string, unknown> = SUMMARY,
  offer: Record<string, unknown> = OFFER,
) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const data = String(config.url).includes("summary") ? summary : [offer]

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{path: "/offers", name: "offers", component: OffersList}],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(OffersList, {
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

describe("OffersList", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("lists what the endpoint returns", async () => {
    const {wrapper} = await mountList()

    const table = wrapper.get('[data-test="offers"]').text()

    expect(table).toContain("Starfleet")
    expect(table).toContain("00001")
    expect(table).toContain("Narendra III")
  })

  // The state names the SPA prints are its own: the Rails locale spelled the
  // canceled state `cancelled`, which no AASM state ever matched.
  it("names the state it was given", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="offers"]').text()).toContain("Sent")
  })

  // The total under a filtered table has to be the total of that table, which
  // is why it comes from its own endpoint rather than from the page.
  it("shows what the filtered set adds up to", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="summary-value"]').text()).toContain("350")
  })

  // The filters are the dropdown buttons the server-rendered list used, not
  // selects: a click opens the menu, a click picks the value.
  it("fills the year filter from the years the account has offers in", async () => {
    const {wrapper} = await mountList()

    await wrapper.get('[data-test="filter-year"]').trigger("click")

    expect(wrapper.find('[data-test="filter-year-2026"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="filter-year-2024"]').exists()).toBe(true)
  })

  // The query is the state, so a filtered, sorted page is a link.
  it("puts a filter in the url and asks the endpoint for it", async () => {
    const requests: AxiosRequestConfig[] = []
    const {wrapper, router} = await mountList(requests)

    await wrapper.get('[data-test="filter-state"]').trigger("click")
    await wrapper.get('[data-test="filter-state-accepted"]').trigger("click")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.state).toBe("accepted")
      expect(requests.some((entry) => entry.params?.state === "accepted")).toBe(true)
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
    const {wrapper, router} = await mountList([], "/offers?page=3")

    expect(wrapper.get('[data-test="page"]').text()).toBe("3")

    await wrapper.get('[data-test="filter-state"]').trigger("click")
    await wrapper.get('[data-test="filter-state-accepted"]').trigger("click")

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

      expect(wrapper.get('[data-test="offers"]').text()).toContain("2026")
      expect(wrapper.get('[data-test="offers"]').text()).not.toContain("28")
    } finally {
      process.env.TZ = original
    }
  })

  // An accepted offer is no longer editable, and an expired trial writes
  // nothing at all — the row must not offer what the API refuses.
  it("offers editing only while the endpoint allows it", async () => {
    const open = await mountList()

    await open.wrapper.get(`[data-test="actions-${OFFER.id}"]`).trigger("click")
    expect(open.wrapper.text()).toContain("Edit")

    const closed = await mountList([], "/offers", SUMMARY, {
      ...OFFER,
      state: "accepted",
      abilities: {update: false, destroy: true, transitions: []},
    })

    await closed.wrapper.get(`[data-test="actions-${OFFER.id}"]`).trigger("click")
    expect(closed.wrapper.text()).not.toContain("Edit")
  })

  // A short page means there is nothing after it.
  it("offers no next page when the page came back short", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="next-page"]').attributes("disabled")).toBeDefined()
    expect(wrapper.get('[data-test="prev-page"]').attributes("disabled")).toBeDefined()
  })

  // A full page says nothing about what follows it: the filtered total does.
  it("offers a next page only while the total says there is one", async () => {
    const full = await mountList([], "/offers", {count: 50, value: "1.0", years: [2026]})

    expect(full.wrapper.get('[data-test="next-page"]').attributes("disabled")).toBeUndefined()

    const last = await mountList([], "/offers?page=2", {count: 50, value: "1.0", years: [2026]})

    expect(last.wrapper.get('[data-test="next-page"]').attributes("disabled")).toBeDefined()
  })
})

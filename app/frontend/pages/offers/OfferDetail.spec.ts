import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import OfferDetail from "./OfferDetail.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ID = "cccccccc-0000-4000-8000-000000000001"

function offer(overrides: Record<string, unknown> = {}) {
  return {
    id: ID,
    ref: 1,
    refNumber: "00001",
    state: "created",
    date: "2026-03-01",
    value: "100.0",
    rate: "90.0",
    description: "Warp core overhaul",
    customerName: "Starfleet",
    projectName: "Narendra III",
    editable: true,
    abilities: {update: true, destroy: true, transitions: ["bid"]},
    positions: [{id: "p1", description: "Design", hours: "2.0", rate: "90.0", value: "180.0"}],
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
    ...overrides,
  }
}

async function mountDetail(record = offer(), requests: AxiosRequestConfig[] = []) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    return {data: record, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/offers", name: "offers", component: {template: "<div />"}},
      {path: "/offers/:id", name: "offer", component: OfferDetail},
      {path: "/offers/:id/edit", name: "offer-edit", component: {template: "<div />"}},
    ],
  })
  await router.push(`/offers/${ID}`)
  await router.isReady()

  const wrapper = mount(OfferDetail, {
    global: {
      plugins: [
        [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
        i18n,
        createPinia(),
        router,
      ],
      // pdf.js needs a real browser; the viewer earns its coverage in the
      // Playwright run, where an actual PDF is rendered.
      stubs: {PdfViewer: true},
    },
  })

  await flushPromises()

  return {wrapper, requests}
}

describe("OfferDetail", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it("shows the offer and its positions", async () => {
    const {wrapper} = await mountDetail()

    expect(wrapper.get('[data-test="offer-title"]').text()).toContain("00001")
    expect(wrapper.get('[data-test="positions"]').text()).toContain("Design")
    expect(wrapper.get('[data-test="value"]').text()).toContain("100")
    expect(wrapper.get('[data-test="description"]').text()).toContain("Warp core overhaul")
  })

  // The endpoint reports what the state machine allows from here, so the
  // buttons cannot offer a transition the API answers with 400.
  it("offers only the transitions the endpoint reports", async () => {
    const {wrapper} = await mountDetail()

    expect(wrapper.find('[data-test="transition-bid"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="transition-accept"]').exists()).toBe(false)
  })

  it("offers accepting, declining and canceling once it is bided", async () => {
    const {wrapper} = await mountDetail(
      offer({state: "bided", abilities: {update: true, destroy: true, transitions: ["accept", "decline", "cancel"]}}),
    )

    expect(wrapper.find('[data-test="transition-bid"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="transition-accept"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="transition-decline"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="transition-cancel"]').exists()).toBe(true)
  })

  it("moves the offer along through the endpoint after a confirm", async () => {
    vi.stubGlobal("confirm", vi.fn(() => true))
    const {wrapper, requests} = await mountDetail()

    await wrapper.get('[data-test="transition-bid"]').trigger("click")

    await vi.waitFor(() => {
      expect(requests.some((entry) => String(entry.url).includes("/transition/bid"))).toBe(true)
    })
  })

  it("leaves the offer alone when the confirm is declined", async () => {
    vi.stubGlobal("confirm", vi.fn(() => false))
    const {wrapper, requests} = await mountDetail()

    await wrapper.get('[data-test="transition-bid"]').trigger("click")
    await flushPromises()

    expect(requests.some((entry) => String(entry.url).includes("/transition"))).toBe(false)
  })

  // An expired trial reads everything and writes nothing, which neither the
  // state nor `editable` says — `editable` is a property of the record, and
  // it disagrees with the ability on a bided offer.
  it("offers nothing to write when the abilities are closed", async () => {
    const {wrapper} = await mountDetail(
      offer({editable: true, abilities: {update: false, destroy: false, transitions: []}}),
    )

    expect(wrapper.find('[data-test="edit"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="delete"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="transition-bid"]').exists()).toBe(false)
    // Reading the PDF is still on offer.
    expect(wrapper.find('[data-test="offer-pdf"]').exists()).toBe(true)
  })

  it("deletes through the endpoint and returns to the list", async () => {
    vi.stubGlobal("confirm", vi.fn(() => true))
    const {wrapper, requests} = await mountDetail()

    await wrapper.get('[data-test="delete"]').trigger("click")

    await vi.waitFor(() => {
      expect(requests.some((entry) => entry.method?.toLowerCase() === "delete")).toBe(true)
    })
  })

  // The API hands over a bare YYYY-MM-DD. Read as UTC midnight and printed in
  // local time, that is the previous day west of Greenwich.
  it("prints the date it was given, in any timezone", async () => {
    const original = process.env.TZ
    process.env.TZ = "America/Los_Angeles"

    try {
      const {wrapper} = await mountDetail()

      expect(wrapper.get('[data-test="facts"]').text()).toContain("2026")
      expect(wrapper.get('[data-test="facts"]').text()).not.toContain("28")
    } finally {
      process.env.TZ = original
    }
  })
})

import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import InvoiceDetail from "./InvoiceDetail.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ID = "dddddddd-0000-4000-8000-000000000001"

function invoice(overrides: Record<string, unknown> = {}) {
  return {
    id: ID,
    ref: 1,
    refNumber: "00001",
    state: "created",
    date: "2026-03-01",
    paymentDueDate: "2026-03-15",
    value: "100.0",
    vat: "19.0",
    customerName: "Starfleet",
    editable: true,
    sendable: false,
    positions: [{id: "p1", description: "Work", hours: "2.0", rate: "90.0", value: "180.0", timerIds: []}],
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
    ...overrides,
  }
}

async function mountDetail(record = invoice(), requests: AxiosRequestConfig[] = []) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    return {data: record, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/invoices", name: "invoices", component: {template: "<div />"}},
      {path: "/invoices/:id", name: "invoice", component: InvoiceDetail},
    ],
  })
  await router.push(`/invoices/${ID}`)
  await router.isReady()

  const wrapper = mount(InvoiceDetail, {
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

describe("InvoiceDetail", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it("shows the invoice and its positions", async () => {
    const {wrapper} = await mountDetail()

    expect(wrapper.get('[data-test="invoice-title"]').text()).toContain("00001")
    expect(wrapper.get('[data-test="positions"]').text()).toContain("Work")
    expect(wrapper.get('[data-test="value"]').text()).toContain("100")
  })

  // The ability allows charging a created invoice and paying a charged one,
  // and answers 403 otherwise — so the buttons follow the state rather than
  // offering what the server will refuse.
  it("offers charging on a created invoice and nothing else", async () => {
    const {wrapper} = await mountDetail()

    expect(wrapper.find('[data-test="charge"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="pay"]').exists()).toBe(false)
  })

  it("offers paying once it is charged", async () => {
    const {wrapper} = await mountDetail(invoice({state: "charged"}))

    expect(wrapper.find('[data-test="charge"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="pay"]').exists()).toBe(true)
  })

  it("charges through the endpoint after a confirm", async () => {
    vi.stubGlobal("confirm", vi.fn(() => true))
    const {wrapper, requests} = await mountDetail()

    await wrapper.get('[data-test="charge"]').trigger("click")

    await vi.waitFor(() => {
      expect(requests.some((entry) => String(entry.url).includes("/charge"))).toBe(true)
    })
  })

  it("leaves the invoice alone when the confirm is declined", async () => {
    vi.stubGlobal("confirm", vi.fn(() => false))
    const {wrapper, requests} = await mountDetail()

    await wrapper.get('[data-test="charge"]').trigger("click")
    await flushPromises()

    expect(requests.some((entry) => String(entry.url).includes("/charge"))).toBe(false)
  })

  // `invoice.timers` is `through: :positions`, so a timesheet exists exactly
  // when some position was built from tracked time.
  it("offers the timesheet only when a position came from timers", async () => {
    const {wrapper} = await mountDetail()
    expect(wrapper.find('[data-test="timesheet-pdf"]').exists()).toBe(false)

    const {wrapper: withTimers} = await mountDetail(
      invoice({positions: [{id: "p1", description: "Work", timerIds: ["t1"]}]}),
    )
    expect(withTimers.find('[data-test="timesheet-pdf"]').exists()).toBe(true)
  })

  it("marks a charged invoice past its due date as overdue", async () => {
    const {wrapper} = await mountDetail(invoice({state: "charged", paymentDueDate: "2020-01-01"}))

    expect(wrapper.find('[data-test="overdue"]').exists()).toBe(true)
  })

  it("does not call an invoice overdue before it is charged", async () => {
    const {wrapper} = await mountDetail(invoice({state: "created", paymentDueDate: "2020-01-01"}))

    expect(wrapper.find('[data-test="overdue"]').exists()).toBe(false)
  })
})

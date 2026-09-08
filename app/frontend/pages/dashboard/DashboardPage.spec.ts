import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {RouterLinkStub} from "@vue/test-utils"
import type {AxiosRequestConfig} from "axios"
import DashboardPage from "./DashboardPage.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

// The chart is stubbed below, but importing it would still pull in the
// vendored Highcharts bundle, whose UMD wrapper exports itself instead of
// registering a global under Vitest's transform. Its options are covered in
// `lib/invoicesChart.spec.ts`.
vi.mock("@/lib/highcharts", () => ({
  Highcharts: {Chart: class {destroy() {}}, setOptions() {}},
}))

const TOTALS = {
  year: 2026,
  uninvoicedAmount: "1200.0",
  chargedSum: "500.0",
  paidSum: "2500.0",
  lastYearPaidSum: "9000.0",
  expensesSum: "300.0",
  lastYearExpensesSum: "800.0",
  openInvoicesCount: 2,
  provision: null,
  lastYearProvision: null,
  overtime: {weeklyHours: "38.0", dailyHours: "7.5", customers: []},
  chart: {
    labels: ["2026-01-01", "2026-02-01"],
    datasets: [{name: "2026", color: "#428bca", data: ["500.0", "700.0"]}],
  },
}

const CHARGED = {
  id: "dddddddd-0000-4000-8000-000000000001",
  ref: 1,
  refNumber: "00001",
  state: "charged",
  date: "2026-03-01",
  paymentDueDate: "2026-03-15",
  value: "500.0",
  vat: "95.0",
  customerName: "Starfleet",
  projectName: "Narendra III",
  positions: [],
  createdAt: "",
  updatedAt: "",
}

interface Options {
  totals?: Record<string, unknown>
  charged?: Record<string, unknown>[]
  paid?: Record<string, unknown>[]
  lastYear?: Record<string, unknown>[]
  projects?: Record<string, unknown>[]
}

async function mountDashboard(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = {}

    if (url.includes("/dashboard")) data = {...TOTALS, ...options.totals}
    else if (url.includes("/projects")) data = options.projects ?? []
    else if (url.includes("/invoices")) {
      const params = config.params ?? {}
      if (params.state === "charged") data = options.charged ?? []
      else if (params.paid_in_year === 2026) data = options.paid ?? []
      else data = options.lastYear ?? []
    }

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const wrapper = mount(DashboardPage, {
    global: {
      plugins: [
        [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
        i18n,
        createPinia(),
      ],
      // Highcharts measures real SVG, which happy-dom does not implement;
      // the options it is handed are covered in `lib/invoicesChart.spec.ts`.
      stubs: {RouterLink: RouterLinkStub, UiChart: true},
    },
  })

  await flushPromises()
  await flushPromises()

  return {wrapper, requests}
}

describe("DashboardPage", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  // happy-dom has no <html lang>, so the i18n plugin falls back to English and
  // the amounts are grouped the English way.
  it("shows the summary the endpoint reports", async () => {
    const {wrapper} = await mountDashboard()

    expect(wrapper.get('[data-test="uninvoiced"]').text()).toContain("1,200")
    expect(wrapper.get('[data-test="charged-sum"]').text()).toContain("500")
    expect(wrapper.get('[data-test="paid-sum"]').text()).toContain("2,500")
  })

  // `all_invoices` was the two sums added up, not a number of its own.
  it("adds the charged and paid sums up for the total", async () => {
    const {wrapper} = await mountDashboard()

    expect(wrapper.get('[data-test="all-sum"]').text()).toContain("3,000")
  })

  // Both provision rows only exist with a rate on the account.
  it("leaves the provision out without a rate", async () => {
    const {wrapper} = await mountDashboard()

    expect(wrapper.find('[data-test="provision"]').exists()).toBe(false)
  })

  it("shows the provision once the account has one", async () => {
    const {wrapper} = await mountDashboard({totals: {provision: "250.0", lastYearProvision: "900.0"}})

    expect(wrapper.get('[data-test="provision"]').text()).toContain("250")
  })

  // `overtime_label` and its siblings: within a quarter of the schedule is
  // green, up to two and a half times it amber, beyond that red.
  it("colours the hours by how far off the schedule they are", async () => {
    const {wrapper} = await mountDashboard()

    expect(wrapper.get('[data-test="weekly-hours"]').classes().join(" ")).toContain("alert-success")

    const {wrapper: heavy} = await mountDashboard({
      totals: {overtime: {weeklyHours: "120.0", dailyHours: "7.5", customers: []}},
    })

    expect(heavy.get('[data-test="weekly-hours"]').classes().join(" ")).toContain("alert-danger")
  })

  it("lists the open invoices with their month", async () => {
    const {wrapper} = await mountDashboard({charged: [CHARGED]})

    const panel = wrapper.get('[data-test="charged-invoices"]')

    expect(panel.text()).toContain("00001")
    expect(panel.text()).toContain("Starfleet")
    expect(panel.text()).toContain("2026")
  })

  // A charged invoice past its due date carries the label the ERB row had.
  it("marks an overdue invoice", async () => {
    const {wrapper} = await mountDashboard({charged: [CHARGED]})

    expect(wrapper.get('[data-test="charged-invoices"]').text()).toContain("overdue")
  })

  it("says so when nothing has been billed at all", async () => {
    const {wrapper} = await mountDashboard()

    expect(wrapper.find('[data-test="nothing-billed"]').exists()).toBe(true)
  })

  // `with_budget` is `where.not(budget: 0).where(budget_on_dashboard: true)`,
  // so a budget alone is not enough to put a project in the panel.
  it("shows a budget bar only for projects that have one and asked for it", async () => {
    const {wrapper} = await mountDashboard({
      projects: [
        {id: "p1", name: "Narendra 3", budget: "1000.0", budgetPercent: "40.0", budgetOnDashboard: true, workflowState: "active", tasks: []},
        {id: "p2", name: "Wolf 359", budget: "0.0", budgetPercent: "0.0", budgetOnDashboard: true, workflowState: "active", tasks: []},
        {id: "p3", name: "Rura Penthe", budget: "2000.0", budgetPercent: "10.0", budgetOnDashboard: false, workflowState: "active", tasks: []},
      ],
    })

    expect(wrapper.find('[data-test="budget-p1"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="budget-p2"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="budget-p3"]').exists()).toBe(false)
  })

  // The panel and each of its rows hung on the year having expenses at all,
  // which the API reports by leaving the sum out.
  it("leaves out the expenses panel for a year without any", async () => {
    const {wrapper} = await mountDashboard({
      totals: {expensesSum: null, lastYearExpensesSum: null},
    })

    expect(wrapper.find('[data-test="expenses-panel"]').exists()).toBe(false)
  })

  it("shows only the year that has expenses", async () => {
    const {wrapper} = await mountDashboard({
      totals: {expensesSum: "300.0", lastYearExpensesSum: null},
    })

    const panel = wrapper.get('[data-test="expenses-panel"]')

    expect(panel.find('[data-test="expenses-sum"]').exists()).toBe(true)
    expect(panel.text()).toContain("This year")
    expect(panel.text()).not.toContain("Last year")
  })

  // The lists are shown in full — the server-rendered dashboard never paged
  // them either.
  it("asks for every invoice rather than a page", async () => {
    const {requests} = await mountDashboard()

    const invoiceCalls = requests.filter((entry) => String(entry.url).includes("/invoices"))

    expect(invoiceCalls.length).toBeGreaterThan(0)
    expect(invoiceCalls.every((entry) => entry.params?.perPage === "all")).toBe(true)
  })
})

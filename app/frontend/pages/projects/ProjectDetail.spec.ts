import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import ProjectDetail from "./ProjectDetail.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

// Highcharts measures real SVG, which happy-dom does not implement; the
// options it is handed are covered in `lib/projectBudgetChart.spec.ts`.
vi.mock("@/lib/highcharts", () => ({
  Highcharts: {Chart: class {destroy() {}}, setOptions() {}},
}))

const ID = "dddddddd-0000-4000-8000-000000000001"

const PROJECT = {
  id: ID,
  name: "Narendra 3",
  customerName: "Starfleet",
  customerId: "cccccccc-0000-4000-8000-000000000001",
  workflowState: "active",
  rate: "90.0",
  budget: "10000.0",
  budgetHours: "100.0",
  budgetPercent: "40.0",
  timerValues: "20.0",
  timerValuesBillable: "16.0",
  timerValuesUninvoiced: "6.0",
  invoiceValues: "2500.0",
  tasks: [{id: "task-1", name: "Away mission", billable: true}],
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

const CHART = {
  labels: ["2026-01-05", "2026-01-12"],
  datasets: [{name: "Budget", color: "#428bca", data: [100, 200], zone: 1}],
  budget: "10000.0",
  ticks: [0],
}

interface Options {
  path?: string
  project?: Record<string, unknown>
  offers?: unknown[]
  invoices?: unknown[]
}

async function mountDetail(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = {}

    if (url.includes("/chart")) data = CHART
    else if (url.includes("/offers")) data = options.offers ?? []
    else if (url.includes("/invoices")) data = options.invoices ?? []
    else if (url.includes("/projects/")) data = {...PROJECT, ...options.project}

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/projects", name: "projects", component: {template: "<div />"}},
      {path: "/projects/:id", name: "project", component: ProjectDetail},
      {path: "/projects/:id/edit", name: "project-edit", component: {template: "<div />"}},
      {path: "/invoices/new", name: "invoice-new", component: {template: "<div />"}},
      {path: "/invoices/:id", name: "invoice", component: {template: "<div />"}},
      {path: "/offers/:id", name: "offer", component: {template: "<div />"}},
      {path: "/timesheet", name: "timesheet", component: {template: "<div />"}},
    ],
  })
  await router.push(options.path ?? `/projects/${ID}`)
  await router.isReady()

  const wrapper = mount(ProjectDetail, {
    global: {
      plugins: [
        [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
        i18n,
        createPinia(),
        router,
      ],
      // The calendar talks to its own endpoints and is covered by its own
      // tests; this screen's business is that it is there and asked for the
      // right project.
      stubs: {TimersCalendar: true},
    },
  })

  await flushPromises()

  return {wrapper, router, requests}
}

describe("ProjectDetail", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("names the project and offers the way back and to the form", async () => {
    const {wrapper} = await mountDetail()

    expect(wrapper.get('[data-test="project-title"]').text()).toBe("Narendra 3")
    expect(wrapper.find('[data-test="back"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="edit"]').exists()).toBe(true)
  })

  // The four numbers along the bottom of the panel, in the order the
  // server-rendered one had them.
  it("works the four numbers out of what the project has booked", async () => {
    const {wrapper} = await mountDetail()

    expect(wrapper.get('[data-test="box-hours"]').text()).toContain("20.00 h")
    // 100 budgeted hours less the 16 billable ones booked.
    expect(wrapper.get('[data-test="box-remaining-hours"]').text()).toContain("84.00 h")
    // 10000 budgeted less the 2500 already invoiced.
    expect(wrapper.get('[data-test="box-remaining-budget"]').text()).toContain("7,500")
    // 6 hours not on an invoice yet, at 90 an hour.
    expect(wrapper.get('[data-test="box-uninvoiced"]').text()).toContain("540")
  })

  // Where the number would be worked out from something the project does not
  // have, the box says so rather than showing a zero.
  it("says n/a where there is nothing to work it out from", async () => {
    const {wrapper} = await mountDetail({
      project: {budget: "0.0", budgetHours: "0.0", rate: null},
    })

    expect(wrapper.get('[data-test="box-remaining-hours"]').text()).toContain("n/a")
    expect(wrapper.get('[data-test="box-remaining-budget"]').text()).toContain("n/a")
    expect(wrapper.get('[data-test="box-uninvoiced"]').text()).toContain("n/a")
  })

  // `budget_progress`: green while there is room, amber past 70, red past 90.
  it("colours the bar by how much of the budget is gone", async () => {
    const {wrapper} = await mountDetail()
    expect(wrapper.get('[data-test="budget-progress"]').html()).toContain("success")

    const {wrapper: warned} = await mountDetail({project: {budgetPercent: "80.0"}})
    expect(warned.get('[data-test="budget-progress"]').html()).toContain("warning")

    const {wrapper: overrun} = await mountDetail({project: {budgetPercent: "95.0"}})
    expect(overrun.get('[data-test="budget-progress"]').html()).toContain("danger")
  })

  it("opens on the times and switches tab by the url", async () => {
    const {wrapper, router} = await mountDetail()

    expect(wrapper.find('[data-test="timers-calendar"]').exists()).toBe(true)

    await wrapper.get('[data-test="tab-tasks"]').trigger("click")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.hash).toBe("#tasks")
      expect(wrapper.get('[data-test="tasks"]').text()).toContain("Away mission")
    })
  })

  it("opens the tab the hash names", async () => {
    const {wrapper} = await mountDetail({path: `/projects/${ID}#invoices`})

    expect(wrapper.find('[data-test="invoices"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="timers-calendar"]').exists()).toBe(false)
  })

  // Both tabs ask for what belongs to this project rather than filtering a
  // whole list in the browser.
  it("asks the endpoints for this project's offers and invoices", async () => {
    const {requests} = await mountDetail()

    const offers = requests.find((entry) => String(entry.url).includes("/offers"))
    const invoices = requests.find((entry) => String(entry.url).includes("/invoices"))

    expect(offers?.params?.project_id).toBe(ID)
    expect(invoices?.params?.project_id).toBe(ID)
  })

  it("says so where a tab has nothing in it", async () => {
    const {wrapper} = await mountDetail({path: `/projects/${ID}#offers`})

    expect(wrapper.find('[data-test="offers-empty"]').exists()).toBe(true)
  })

  it("offers no fields at all when the project could not be loaded", async () => {
    AXIOS_INSTANCE.defaults.adapter = async () => {
      throw {response: {status: 500, data: {}}}
    }

    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        {path: "/projects", name: "projects", component: {template: "<div />"}},
        {path: "/projects/:id", name: "project", component: ProjectDetail},
        {path: "/projects/:id/edit", name: "project-edit", component: {template: "<div />"}},
      ],
    })
    await router.push(`/projects/${ID}`)
    await router.isReady()

    const wrapper = mount(ProjectDetail, {
      global: {
        plugins: [
          [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
          i18n,
          createPinia(),
          router,
        ],
        stubs: {TimersCalendar: true},
      },
    })

    await vi.waitFor(() => expect(wrapper.find('[data-test="load-failed"]').exists()).toBe(true))

    expect(wrapper.find('[data-test="budget-panel"]').exists()).toBe(false)
  })
})

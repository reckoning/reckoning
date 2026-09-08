import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import ExpensesList from "./ExpensesList.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const EXPENSE = {
  id: "aaaaaaaa-0000-4000-8000-000000000001",
  expenseType: "gwg",
  description: "Tricorder",
  seller: "Daystrom Institute",
  date: "2026-03-01",
  value: "100.0",
  usableValue: "90.0",
  vatPercent: 19,
  vatValue: "17.1",
  privateUsePercent: 10,
  interval: "once",
  startedAt: null,
  endedAt: null,
  afaTypeId: null,
  hasReceipt: false,
  needsReceipt: true,
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

const SUMMARY = {count: 1, value: "90.0", vat: "17.1", years: [2026, 2025]}

interface Options {
  expenses?: Record<string, unknown>[]
  summary?: Record<string, unknown>
  path?: string
  bulk?: () => unknown
}

async function mountList(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = [EXPENSE]

    if (url.includes("summary")) data = options.summary ?? SUMMARY
    else if (url.includes("bulk")) data = options.bulk?.() ?? {count: 1, message: "Done."}
    else if (url.includes("/expenses")) data = options.expenses ?? [EXPENSE]

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{path: "/expenses", name: "expenses", component: ExpensesList}],
  })
  await router.push(options.path ?? "/expenses")
  await router.isReady()

  const wrapper = mount(ExpensesList, {
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

describe("ExpensesList", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("lists what the endpoint returns", async () => {
    const {wrapper} = await mountList()

    const list = wrapper.get('[data-test="expenses"]').text()

    expect(list).toContain("Tricorder")
    expect(list).toContain("Low-value assets")
  })

  // The amount on the right of a row is what the expense deducts, not what
  // it cost: 100 at 10% private use deducts 90.
  it("prints the deductible amount, not the value", async () => {
    const {wrapper} = await mountList()

    const row = wrapper.get(`[data-test="expense-${EXPENSE.id}"]`).text()

    expect(row).toContain("90")
    expect(row).not.toContain("100")
  })

  // The total under a filtered table has to be the total of that table,
  // which is why it comes from its own endpoint.
  it("shows what the filtered set adds up to", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.get('[data-test="summary-value"]').text()).toContain("90")
    expect(wrapper.get('[data-test="summary-vat"]').text()).toContain("17")
  })

  it("marks a row whose receipt is missing", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.find(`[data-test="receipt-missing-${EXPENSE.id}"]`).exists()).toBe(true)
    expect(wrapper.find(`[data-test="receipt-${EXPENSE.id}"]`).exists()).toBe(false)
  })

  it("marks a row that has one", async () => {
    const {wrapper} = await mountList({expenses: [{...EXPENSE, hasReceipt: true}]})

    expect(wrapper.find(`[data-test="receipt-${EXPENSE.id}"]`).exists()).toBe(true)
  })

  // A business expense files no receipt, so the row must not ask for one.
  it("asks for no receipt where none is needed", async () => {
    const {wrapper} = await mountList({
      expenses: [{...EXPENSE, expenseType: "home_office", needsReceipt: false}],
    })

    expect(wrapper.find(`[data-test="receipt-missing-${EXPENSE.id}"]`).exists()).toBe(false)
  })

  // A one-off prints its date; an interval prints how often and how long.
  it("prints the interval and its span instead of a date", async () => {
    const {wrapper} = await mountList({
      expenses: [
        {
          ...EXPENSE,
          date: null,
          interval: "monthly",
          startedAt: "2026-01-01",
          endedAt: "2026-12-31",
        },
      ],
    })

    const row = wrapper.get(`[data-test="expense-${EXPENSE.id}"]`).text()

    expect(row).toContain("Monthly")
    expect(row).toContain("-")
  })

  it("fills the year filter from the years the summary offers", async () => {
    const {wrapper} = await mountList()

    await wrapper.get('[data-test="filter-year"]').trigger("click")

    expect(wrapper.find('[data-test="filter-year-2026"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="filter-year-2025"]').exists()).toBe(true)
  })

  // The query is the state, so a filtered page is a link someone can send.
  it("puts a filter in the url and asks the endpoint for it", async () => {
    const {wrapper, router, requests} = await mountList()

    await wrapper.get('[data-test="filter-type"]').trigger("click")
    await wrapper.get('[data-test="filter-type-afa"]').trigger("click")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.type).toBe("afa")
      expect(requests.some((entry) => entry.params?.type === "afa")).toBe(true)
    })
  })

  it("searches on submit rather than on every keystroke", async () => {
    const {wrapper, router, requests} = await mountList()

    await wrapper.get('[data-test="search"]').setValue("tric")

    expect(requests.some((entry) => entry.params?.query)).toBe(false)

    await wrapper.get('[data-test="search-form"]').trigger("submit")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.query.query).toBe("tric")
      expect(requests.some((entry) => entry.params?.query === "tric")).toBe(true)
    })
  })

  it("offers to clear a search that is on", async () => {
    const {wrapper, router} = await mountList({path: "/expenses?query=tric"})

    await wrapper.get('[data-test="search-reset"]').trigger("click")

    await vi.waitFor(() => expect(router.currentRoute.value.query.query).toBeUndefined())
  })

  // The bar only exists once something is ticked, the way the
  // server-rendered one slid out.
  it("keeps the bulk bar away until a row is picked", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.find('[data-test="bulk-bar"]').exists()).toBe(false)

    await wrapper.get(`[data-test="select-${EXPENSE.id}"]`).setValue(true)

    expect(wrapper.get('[data-test="bulk-bar"]').text()).toContain("1 selected")
  })

  it("picks and drops every row at once", async () => {
    const {wrapper} = await mountList()

    await wrapper.get('[data-test="select-all"]').setValue(true)
    expect(wrapper.get('[data-test="bulk-count"]').text()).toContain("1 selected")

    await wrapper.get('[data-test="select-all"]').setValue(false)
    expect(wrapper.find('[data-test="bulk-bar"]').exists()).toBe(false)
  })

  // Only the fields that were filled in travel: an empty one means "leave
  // this one alone".
  it("sends only the fields the bulk bar filled in", async () => {
    const {wrapper, requests} = await mountList()

    await wrapper.get(`[data-test="select-${EXPENSE.id}"]`).setValue(true)
    await wrapper.get('[data-test="bulk-vat"]').setValue("7")
    await wrapper.get('[data-test="bulk-apply"]').trigger("click")

    await vi.waitFor(() => {
      const call = requests.find((entry) => String(entry.url).includes("bulk_update"))

      expect(call).toBeTruthy()
      expect(JSON.parse(String(call?.data))).toEqual({
        expenseIds: [EXPENSE.id],
        vat_percent: 7,
      })
    })
  })

  it("does nothing when the bulk bar has nothing to apply", async () => {
    const {wrapper, requests} = await mountList()

    await wrapper.get(`[data-test="select-${EXPENSE.id}"]`).setValue(true)
    await wrapper.get('[data-test="bulk-apply"]').trigger("click")
    await flushPromises()

    expect(requests.some((entry) => String(entry.url).includes("bulk_update"))).toBe(false)
  })

  // The exports are still rendered by the server, so the link has to carry
  // the filters the table is showing.
  it("carries the filters into the export links", async () => {
    const {wrapper} = await mountList({path: "/expenses?year=2026&type=afa"})

    const pdf = wrapper.get('[data-test="export-pdf"]').attributes("href")

    expect(pdf).toContain("/expenses.pdf?")
    expect(pdf).toContain("year=2026")
    expect(pdf).toContain("type=afa")
    expect(wrapper.get('[data-test="export-csv"]').attributes("href")).toContain("/expenses.csv?")
  })

  it("says so when there is nothing to show", async () => {
    const {wrapper} = await mountList({expenses: [], summary: {...SUMMARY, count: 0}})

    expect(wrapper.get('[data-test="empty"]').text()).toContain("No expenses")
  })
})

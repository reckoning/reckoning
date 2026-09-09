import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import ExpenseForm from "./ExpenseForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ID = "aaaaaaaa-0000-4000-8000-000000000001"

const EXPENSE = {
  id: ID,
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
  receipt: null,
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

const AFA_TYPES = [{id: "bbbbbbbb-0000-4000-8000-000000000001", name: "Computer", value: 3}]

interface Options {
  path?: string
  expense?: Record<string, unknown>
}

async function mountForm(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = {}

    if (url.includes("afa_types")) data = AFA_TYPES
    else if (config.method === "post" || config.method === "patch" || config.method === "put") {
      data = {...EXPENSE, ...options.expense}
    } else if (url.includes("/expenses/")) data = {...EXPENSE, ...options.expense}

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/expenses", name: "expenses", component: {template: "<div />"}},
      {path: "/expenses/new", name: "expense-new", component: ExpenseForm},
      {path: "/expenses/:id/edit", name: "expense-edit", component: ExpenseForm},
    ],
  })
  await router.push(options.path ?? "/expenses/new")
  await router.isReady()

  const wrapper = mount(ExpenseForm, {
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

// Submitting runs the validation and then the mutation, so both the body and
// the errors it prints instead arrive a few ticks later.
async function body(requests: AxiosRequestConfig[], method: "post" | "patch") {
  return vi.waitFor(() => {
    const call = requests.find((entry) => entry.method?.toLowerCase() === method)
    expect(call).toBeTruthy()

    return JSON.parse(String(call?.data))
  })
}

describe("ExpenseForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("opens empty for a new expense, on a one-off", async () => {
    const {wrapper} = await mountForm()

    expect(wrapper.get('[data-test="expense-title"]').text()).toContain("New expense")
    expect((wrapper.get('[data-test="interval"]').element as HTMLSelectElement).value).toBe("once")
    expect(wrapper.find('[data-test="date-field"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="started-at-field"]').exists()).toBe(false)
  })

  it("fills the fields from the expense it is editing", async () => {
    const {wrapper} = await mountForm({path: `/expenses/${ID}/edit`})

    expect((wrapper.get('[data-test="description"]').element as HTMLInputElement).value).toBe(
      "Tricorder",
    )
    expect((wrapper.get('[data-test="value"]').element as HTMLInputElement).value).toBe("100")
    expect((wrapper.get('[data-test="vat-percent"]').element as HTMLInputElement).value).toBe("19")
  })

  // `expense-interval#toggle`: a one-off has a date, everything else a span.
  it("swaps the date for a span once it repeats", async () => {
    const {wrapper} = await mountForm()

    await wrapper.get('[data-test="interval"]').setValue("monthly")

    expect(wrapper.find('[data-test="date-field"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="started-at"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="ended-at"]').exists()).toBe(true)
  })

  // Only an AfA expense is written off, so only it asks for a class.
  it("asks for a depreciation class only for afa", async () => {
    const {wrapper} = await mountForm()

    expect(wrapper.find('[data-test="afa-type"]').exists()).toBe(false)

    await wrapper.get('[data-test="expense-type"]').setValue("afa")

    expect(wrapper.find('[data-test="afa-type"]').exists()).toBe(true)
    expect(wrapper.get('[data-test="afa-type"]').text()).toContain("Computer")
  })

  it("refuses to save without what the record needs", async () => {
    const {wrapper, requests} = await mountForm()

    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() => {
      expect(wrapper.find('[data-test="expense-type-error"]').exists()).toBe(true)
      expect(wrapper.find('[data-test="description-error"]').exists()).toBe(true)
      expect(wrapper.find('[data-test="seller-error"]').exists()).toBe(true)
    })

    expect(requests.some((entry) => entry.method?.toLowerCase() === "post")).toBe(false)
  })

  // The model validates the class for an afa expense, so the form says so
  // before the endpoint has to.
  it("refuses an afa expense with no class", async () => {
    const {wrapper} = await mountForm()

    await wrapper.get('[data-test="expense-type"]').setValue("afa")
    await wrapper.get('[data-test="description"]').setValue("Notebook")
    await wrapper.get('[data-test="seller"]').setValue("ACME")
    await wrapper.get('[data-test="value"]').setValue("1200")
    await wrapper.get('[data-test="date"]').setValue("2026-03-01")
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() =>
      expect(wrapper.find('[data-test="afa-type-error"]').exists()).toBe(true),
    )
  })

  it("refuses a span that ends before it starts", async () => {
    const {wrapper} = await mountForm()

    await wrapper.get('[data-test="expense-type"]').setValue("current")
    await wrapper.get('[data-test="interval"]').setValue("monthly")
    await wrapper.get('[data-test="description"]').setValue("Rent")
    await wrapper.get('[data-test="seller"]').setValue("ACME")
    await wrapper.get('[data-test="value"]').setValue("100")
    await wrapper.get('[data-test="started-at"]').setValue("2026-06-01")
    await wrapper.get('[data-test="ended-at"]').setValue("2026-01-01")
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() =>
      expect(wrapper.find('[data-test="ended-at-error"]').exists()).toBe(true),
    )
  })

  it("sends what was typed and returns to the list", async () => {
    const {wrapper, requests, router} = await mountForm()

    await wrapper.get('[data-test="expense-type"]').setValue("gwg")
    await wrapper.get('[data-test="description"]').setValue("Tricorder")
    await wrapper.get('[data-test="seller"]').setValue("Daystrom Institute")
    await wrapper.get('[data-test="value"]').setValue("100")
    await wrapper.get('[data-test="date"]').setValue("2026-03-01")
    await wrapper.get('[data-test="private-use-percent"]').setValue("10")
    await wrapper.get("form").trigger("submit")

    expect(await body(requests, "post")).toMatchObject({
      expense_type: "gwg",
      description: "Tricorder",
      seller: "Daystrom Institute",
      value: "100",
      date: "2026-03-01",
      private_use_percent: 10,
      interval: "once",
    })

    await vi.waitFor(() => expect(router.currentRoute.value.name).toBe("expenses"))
  })

  // The fields the interval is not asking for are cleared rather than
  // carrying whatever was typed before it changed.
  it("sends no date for something that repeats", async () => {
    const {wrapper, requests} = await mountForm()

    await wrapper.get('[data-test="expense-type"]').setValue("current")
    await wrapper.get('[data-test="date"]').setValue("2026-03-01")
    await wrapper.get('[data-test="interval"]').setValue("monthly")
    await wrapper.get('[data-test="description"]').setValue("Rent")
    await wrapper.get('[data-test="seller"]').setValue("ACME")
    await wrapper.get('[data-test="value"]').setValue("100")
    await wrapper.get('[data-test="started-at"]').setValue("2026-01-01")
    await wrapper.get("form").trigger("submit")

    expect(await body(requests, "post")).toMatchObject({date: null, started_at: "2026-01-01"})
  })

  // `to_prefill_params`: the copy button opens a form with everything filled
  // in and nothing saved.
  it("fills itself from the query a copy carries", async () => {
    const {wrapper} = await mountForm({
      path: "/expenses/new?expense_type=licenses&description=Editor&seller=ACME&value=99",
    })

    expect((wrapper.get('[data-test="expense-type"]').element as HTMLSelectElement).value).toBe(
      "licenses",
    )
    expect((wrapper.get('[data-test="description"]').element as HTMLInputElement).value).toBe(
      "Editor",
    )
    expect((wrapper.get('[data-test="value"]').element as HTMLInputElement).value).toBe("99")
  })

  // The list's filters travel with the links, so cancelling lands back on
  // the list that sent you here.
  it("returns to the list it was opened from", async () => {
    const {wrapper, router} = await mountForm({path: "/expenses/new?type=afa&year=2026"})

    await wrapper.get('[data-test="cancel"]').trigger("click")
    await flushPromises()

    expect(router.currentRoute.value.name).toBe("expenses")
    expect(router.currentRoute.value.query).toEqual({type: "afa", year: "2026"})
  })

  it("says a receipt is missing, and links the one that is there", async () => {
    const {wrapper} = await mountForm({path: `/expenses/${ID}/edit`})

    expect(wrapper.find('[data-test="receipt-missing"]').exists()).toBe(true)

    const {wrapper: withReceipt} = await mountForm({
      path: `/expenses/${ID}/edit`,
      expense: {
        hasReceipt: true,
        receipt: {url: "/rails/blob/receipt.pdf", filename: "receipt.pdf", contentType: "application/pdf"},
      },
    })

    expect(withReceipt.get('[data-test="receipt-link"]').attributes("href")).toBe(
      "/rails/blob/receipt.pdf",
    )
    expect(withReceipt.find('[data-test="receipt-missing"]').exists()).toBe(false)
  })

  // An image is shown as one; only a pdf goes through the viewer.
  it("shows an image receipt as an image", async () => {
    const {wrapper} = await mountForm({
      path: `/expenses/${ID}/edit`,
      expense: {
        hasReceipt: true,
        receipt: {url: "/rails/blob/receipt.png", filename: "receipt.png", contentType: "image/png"},
      },
    })

    expect(wrapper.find('[data-test="receipt-image"]').exists()).toBe(true)
  })

  // The amount an expense deducts is not what it cost, and the difference is
  // the private share being typed above it.
  it("shows what the expense deducts while it is typed", async () => {
    const {wrapper} = await mountForm()

    await wrapper.get('[data-test="value"]').setValue("200")
    await wrapper.get('[data-test="private-use-percent"]').setValue("25")

    expect(wrapper.get('[data-test="deductible"]').text()).toContain("150")
  })
})

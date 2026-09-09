import {describe, it, expect, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import ExpenseImportPage from "./ExpenseImportPage.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const COLUMNS = [
  {name: "id", type: "uuid"},
  {name: "value", type: "decimal"},
]

const ROWS = [
  {
    id: "eeeeeeee-0000-4000-8000-000000000001",
    date: "2026-03-04",
    value: "42.5",
    vatPercent: 19,
    privateUsePercent: 0,
    interval: "once",
    afaTypeId: null,
    startedAt: null,
    endedAt: null,
    seller: "Daystrom Institute",
    description: "Positronic spares",
    expenseType: "licenses",
  },
  {
    id: null,
    date: "2026-03-05",
    value: "9.99",
    vatPercent: 19,
    privateUsePercent: 0,
    interval: "once",
    afaTypeId: null,
    startedAt: null,
    endedAt: null,
    seller: "Utopia Planitia",
    description: "Coffee",
    expenseType: "current",
  },
]

interface Options {
  path?: string
  rows?: unknown[]
  refusePreview?: boolean
  refuseCreate?: unknown
}

async function mountPage(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)

    if (url.includes("preview")) {
      if (options.refusePreview) {
        throw {response: {status: 422, data: {code: "validation_error.expense.import"}}}
      }

      return {
        data: {rows: options.rows ?? ROWS},
        status: 200,
        statusText: "OK",
        headers: {},
        config,
      }
    }

    if (url.includes("columns")) {
      return {data: {columns: COLUMNS}, status: 200, statusText: "OK", headers: {}, config}
    }

    if (options.refuseCreate) throw options.refuseCreate

    return {data: {count: 2}, status: 201, statusText: "Created", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/expenses", name: "expenses", component: {template: "<div />"}},
      {path: "/expenses/import", name: "expense-import", component: ExpenseImportPage},
    ],
  })

  await router.push(options.path ?? "/expenses/import")
  await router.isReady()

  const wrapper = mount(ExpenseImportPage, {
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

// The file input cannot be filled from a test, so the picked file is handed
// to the change handler the way the browser would.
async function pickFile(wrapper: Awaited<ReturnType<typeof mountPage>>["wrapper"]) {
  const file = new File(["Date,Name,Purpose,Amount,Currency\n"], "statement.csv", {
    type: "text/csv",
  })
  const input = wrapper.get('[data-test="file"]')

  Object.defineProperty(input.element, "files", {value: [file], configurable: true})
  await input.trigger("change")
}

describe("ExpenseImportPage", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  it("spells out the columns an exported csv carries", async () => {
    const {wrapper} = await mountPage()

    expect(wrapper.get('[data-test="import-columns"]').text()).toContain("id")
    expect(wrapper.get('[data-test="import-columns"]').text()).toContain("decimal")
  })

  it("cannot go on until a file is picked", async () => {
    const {wrapper} = await mountPage()

    expect(wrapper.get('[data-test="continue"]').attributes("disabled")).toBeDefined()

    await pickFile(wrapper)

    expect(wrapper.get('[data-test="continue"]').attributes("disabled")).toBeUndefined()
  })

  it("sends the file and the defaults as one multipart body", async () => {
    const {wrapper, requests} = await mountPage()

    await pickFile(wrapper)
    await wrapper.get('[data-test="expense-type"]').setValue("licenses")
    await wrapper.get('[data-test="vat-percent"]').setValue("7")
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    const preview = requests.find((entry) => String(entry.url).includes("preview"))
    const body = preview?.data as FormData

    expect(body).toBeInstanceOf(FormData)
    expect(body.get("expense_type")).toBe("licenses")
    expect(body.get("vat_percent")).toBe("7")
    expect(body.get("skip_credits")).toBe("true")
  })

  it("shows what came out of the file, with every row picked", async () => {
    const {wrapper} = await mountPage()

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    expect(wrapper.findAll('[data-test="preview-rows"] tbody tr')).toHaveLength(2)
    expect(
      (wrapper.get('[data-test="seller-0"]').element as HTMLInputElement).value,
    ).toBe("Daystrom Institute")
    expect(
      (wrapper.get('[data-test="include-0"]').element as HTMLInputElement).checked,
    ).toBe(true)
  })

  // The whole point of the preview: what goes in is what the table shows,
  // including the id that decides update-or-create.
  it("imports the rows that are still ticked, as edited", async () => {
    const {wrapper, requests, router} = await mountPage()

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    await wrapper.get('[data-test="seller-0"]').setValue("Daystrom")
    await wrapper.get('[data-test="type-0"]').setValue("gwg")
    await wrapper.get('[data-test="include-1"]').setValue(false)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    // A JSON body is already serialized by the time the adapter sees it.
    const created = requests.find((entry) => String(entry.url).endsWith("/expense_imports"))
    const rows = JSON.parse(String(created?.data)).rows as Record<string, unknown>[]

    expect(rows).toHaveLength(1)
    expect(rows[0].seller).toBe("Daystrom")
    expect(rows[0].expense_type).toBe("gwg")
    expect(rows[0].id).toBe(ROWS[0].id)
    expect(router.currentRoute.value.name).toBe("expenses")
  })

  it("keeps the filters the list was showing", async () => {
    const {wrapper, router} = await mountPage({path: "/expenses/import?year=2025&type=licenses"})

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    expect(router.currentRoute.value.query).toEqual({year: "2025", type: "licenses"})
  })

  it("says nothing could be read out of the file", async () => {
    const {wrapper} = await mountPage({refusePreview: true})

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    expect(wrapper.get('[data-test="import-errors"]').text()).toContain("row")
    expect(wrapper.find('[data-test="preview-rows"]').exists()).toBe(false)
  })

  // A row the server refuses names its line, and the preview stays put so it
  // can be corrected.
  it("keeps the preview when the import is refused", async () => {
    const {wrapper} = await mountPage({
      refuseCreate: {
        response: {
          status: 422,
          data: {
            code: "validation_error.expense.import",
            message: "no",
            errors: {base: ["Row 1: Description is required"]},
          },
        },
      },
    })

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    expect(wrapper.get('[data-test="import-errors"]').text()).toContain("Row 1")
    expect(wrapper.findAll('[data-test="preview-rows"] tbody tr')).toHaveLength(2)
  })

  it("refuses to import nothing", async () => {
    const {wrapper, requests} = await mountPage()

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    await wrapper.get('[data-test="include-0"]').setValue(false)
    await wrapper.get('[data-test="include-1"]').setValue(false)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    expect(wrapper.find('[data-test="import-errors"]').exists()).toBe(true)
    expect(
      requests.filter((entry) => String(entry.url).endsWith("/expense_imports")),
    ).toHaveLength(0)
  })

  it("goes back to the upload from the preview", async () => {
    const {wrapper, router} = await mountPage()

    await pickFile(wrapper)
    await wrapper.get('form').trigger("submit")
    await flushPromises()

    await wrapper.get('[data-test="back"]').trigger("click")
    await flushPromises()

    expect(wrapper.find('[data-test="preview-rows"]').exists()).toBe(false)
    expect(wrapper.find('[data-test="file"]').exists()).toBe(true)
    expect(router.currentRoute.value.name).toBe("expense-import")
  })
})

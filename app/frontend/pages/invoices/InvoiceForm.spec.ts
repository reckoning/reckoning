import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import InvoiceForm from "./InvoiceForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const INVOICE_ID = "dddddddd-0000-4000-8000-000000000001"
const PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000001"
const POSITION_ID = "eeeeeeee-0000-4000-8000-000000000001"
const OTHER_PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000002"
const RATELESS_PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000003"

interface Options {
  invoice?: Record<string, unknown>
  account?: Record<string, unknown>
  uninvoiced?: Record<string, unknown>[]
  invoiceStatus?: number
}

// The schema calls `rate` nullable, so a client cannot assume a value.
const PROJECT_RATES: Record<string, string | null> = {
  [PROJECT_ID]: "90.0",
  [OTHER_PROJECT_ID]: "50.0",
  [RATELESS_PROJECT_ID]: null,
}

function respond(requests: AxiosRequestConfig[], options: Options) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = {}

    if (url.includes("/timers/uninvoiced")) data = options.uninvoiced ?? []
    else if (url.includes("/account")) data = {id: "acc", name: "Enterprise", address: "Sector 001", ...options.account}
    else if (url.includes("/projects/")) {
      const requested = url.split("/projects/")[1]

      data = {
        id: requested,
        name: "Narendra 3",
        rate: requested in PROJECT_RATES ? PROJECT_RATES[requested] : "90.0",
        workflowState: "active",
        tasks: [],
      }
    } else if (url.includes("/projects")) {
      data = [
        {id: PROJECT_ID, name: "Narendra 3", label: "Narendra 3", workflowState: "active", tasks: []},
        {id: OTHER_PROJECT_ID, name: "Outpost 6", label: "Outpost 6", workflowState: "active", tasks: []},
        {id: RATELESS_PROJECT_ID, name: "Rateless", label: "Rateless", workflowState: "active", tasks: []},
      ]
    } else if (url.includes("/invoices")) data = options.invoice ?? {}

    if (url.includes("/invoices/") && options.invoiceStatus) {
      throw Object.assign(new Error(`Request failed with status ${options.invoiceStatus}`), {config})
    }

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }
}

async function mountForm(path: string, options: Options = {}) {
  const requests: AxiosRequestConfig[] = []
  respond(requests, options)

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/invoices", name: "invoices", component: {template: "<div />"}},
      {path: "/invoices/new", name: "invoice-new", component: InvoiceForm},
      {path: "/invoices/:id", name: "invoice", component: {template: "<div />"}},
      {path: "/invoices/:id/edit", name: "invoice-edit", component: InvoiceForm},
    ],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(InvoiceForm, {
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
  await flushPromises()

  return {wrapper, requests}
}

async function submitted(requests: AxiosRequestConfig[], method: "post" | "patch") {
  return vi.waitFor(() => {
    const request = requests.find((entry) => entry.method?.toLowerCase() === method)
    expect(request).toBeTruthy()

    return JSON.parse(String(request?.data))
  })
}

describe("InvoiceForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  // What the ERB recomputed on every keystroke: hours imply the project's
  // rate, and hours with a rate imply the value.
  it("fills the rate from the project and computes the value", async () => {
    const {wrapper} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")

    // Decimals cross the wire as strings, so the project's rate arrives as
    // "90.0" — which is what the ERB put in the field too.
    expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("90.0")
    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("180")
  })

  it("leaves the value editable on a position without hours", async () => {
    const {wrapper} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`)

    expect(wrapper.find('[data-test="position-value-0"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="position-value-computed-0"]').exists()).toBe(false)
  })

  // A generated row's hours belong to the timers behind it, so they are shown
  // rather than offered for editing — which is what the second ERB partial
  // was for.
  it("takes uninvoiced time as one position per task", async () => {
    const {wrapper, requests} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`, {
      uninvoiced: [
        {id: "t1", taskId: "task-1", taskName: "Away mission", value: "1.5", started: false, invoiced: false, deleted: false, createdAt: "", updatedAt: ""},
        {id: "t2", taskId: "task-1", taskName: "Away mission", value: "0.5", started: false, invoiced: false, deleted: false, createdAt: "", updatedAt: ""},
        {id: "t3", taskId: "task-2", taskName: "Shore leave", value: "3.0", started: false, invoiced: false, deleted: false, createdAt: "", updatedAt: ""},
      ],
    })

    await wrapper.get('[data-test="generate-positions"]').trigger("click")
    await flushPromises()

    await wrapper.get('[data-test="candidate-task-1"] input').setValue(true)
    await wrapper.get('[data-test="take-picked"]').trigger("click")
    await flushPromises()

    // The two timers of that task add up, and the hours are fixed.
    expect(wrapper.get('[data-test="position-hours-fixed-1"]').text()).toBe("2")
    expect((wrapper.get('[data-test="position-description-1"]').element as HTMLInputElement).value)
      .toBe("Away mission")

    await wrapper.get('form').trigger("submit")
    const body = await submitted(requests, "post")
    const generated = body.positions_attributes.at(-1)

    expect(generated.timer_ids).toEqual(["t1", "t2"])
    expect(generated.value).toBe("180")
  })

  // Generated rows carry the timers of the project they came from, and the
  // invoice takes its customer and its rate from the project — so switching
  // the project cannot keep them around.
  it("drops generated positions when the project changes", async () => {
    const {wrapper, requests} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`, {
      uninvoiced: [
        {id: "t1", taskId: "task-1", taskName: "Away mission", value: "2.0", started: false, invoiced: false, deleted: false, createdAt: "", updatedAt: ""},
      ],
    })

    await wrapper.get('[data-test="generate-positions"]').trigger("click")
    await flushPromises()
    await wrapper.get('[data-test="candidate-task-1"] input').setValue(true)
    await wrapper.get('[data-test="take-picked"]').trigger("click")
    await flushPromises()

    const generated = () => wrapper.find('[data-test="position-description-1"]')

    expect((generated().element as HTMLInputElement).value).toBe("Away mission")

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await flushPromises()

    expect(generated().exists()).toBe(false)

    await wrapper.get("form").trigger("submit")
    const body = await submitted(requests, "post")

    expect(body.project_id).toBe(OTHER_PROJECT_ID)
    expect(body.positions_attributes.some((position: {timer_ids: string[]}) => position.timer_ids.length))
      .toBe(false)
  })

  // What the ERB tracked as `oldProjectRate`: a rate the project filled in
  // follows the new project.
  it("carries a rate it filled in over to the new project", async () => {
    const {wrapper} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("90.0")

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)

    // The new project's rate arrives with its own request.
    await vi.waitFor(() => {
      expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("50.0")
    })

    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("100")
  })

  // Comparing the rate against the project's would mistake a hand-typed rate
  // that happens to match for one this form filled in.
  it("leaves a hand-typed rate alone when the project changes", async () => {
    const {wrapper} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`)

    // Exactly the project's rate, but typed rather than filled in.
    await wrapper.get('[data-test="position-rate-0"]').setValue("90.0")
    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await flushPromises()
    await flushPromises()

    // A number input hands back "90" for the typed "90.0"; what matters is
    // that it is not the new project's 50.
    expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("90")
    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("180")
  })

  // The project query blanks out while the newly picked project loads, and a
  // blank rate is indistinguishable from a project that has none — which is
  // why the carry keys on the record rather than on the rate.
  it("clears a carried rate when the new project has none", async () => {
    const {wrapper} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("90.0")

    await wrapper.get('[data-test="project"]').setValue(RATELESS_PROJECT_ID)

    await vi.waitFor(() => {
      expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("")
    })

    // Nothing left to derive the value from, so the stale one is gone rather
    // than being billed.
    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("")
  })

  // The ERB form rendered the project select for `new` and `edit` alike, and
  // the API still takes a project change — the port had dropped it.
  it("offers the project on the edit form too", async () => {
    const {wrapper} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        projectId: PROJECT_ID,
        positions: [],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    expect(wrapper.find('[data-test="project"]').exists()).toBe(true)
  })

  // `belongs_to :project` is required. Offering "no project" on an existing
  // invoice promised a clearing that the PATCH quietly dropped — the field
  // said one thing, the record kept another.
  it("offers no empty project on an existing invoice", async () => {
    const {wrapper} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        projectId: PROJECT_ID,
        positions: [],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    const values = wrapper.get('[data-test="project"]').findAll("option").map((option) => option.attributes("value"))

    expect(values).not.toContain("")
    expect(values).toContain(PROJECT_ID)
  })

  // `GET /projects` answers with the active ones, and a project can be
  // archived long after an invoice was written against it. Without its own
  // project in the list the required select has nothing to match, and the
  // invoice cannot be saved at all.
  it("keeps an archived project selectable on its own invoice", async () => {
    const ARCHIVED = "aaaaaaaa-0000-4000-8000-000000000099"
    const {wrapper} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        projectId: ARCHIVED,
        projectName: "Sternenbasis 12",
        positions: [],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    const select = wrapper.get('[data-test="project"]')

    expect(select.findAll("option").map((option) => option.attributes("value"))).toContain(ARCHIVED)
    expect((select.element as HTMLSelectElement).value).toBe(ARCHIVED)
  })

  // Only time is bound to a project. A position someone typed belongs to the
  // invoice and has to survive a project change — tagging it along with the
  // generated ones deleted it on save.
  it("keeps a hand-typed position through a project change", async () => {
    const {wrapper, requests} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        projectId: PROJECT_ID,
        positions: [
          {id: POSITION_ID, description: "Beratung", hours: "3.0", rate: "80.0", value: "240.0", timerIds: []},
        ],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await flushPromises()

    expect((wrapper.get('[data-test="position-description-0"]').element as HTMLInputElement).value)
      .toBe("Beratung")

    await wrapper.get("form").trigger("submit")
    const body = await submitted(requests, "patch")
    const saved = body.positions_attributes.find((position: {id?: string}) => position.id === POSITION_ID)

    expect(saved._destroy).toBeUndefined()
    expect(saved.description).toBe("Beratung")
  })

  // Switching the project is a choice, not a demolition: a row is only
  // decided about when the form is submitted, so passing through another
  // project on the way leaves the invoice as it was.
  it("brings a generated row back when the project comes back", async () => {
    const {wrapper, requests} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        projectId: PROJECT_ID,
        positions: [
          {id: POSITION_ID, description: "Away mission", hours: "2.0", rate: "90.0", value: "180.0", timerIds: ["t1"]},
        ],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await flushPromises()

    expect(wrapper.find('[data-test="position-description-0"]').exists()).toBe(false)

    await wrapper.get('[data-test="project"]').setValue(PROJECT_ID)
    await flushPromises()

    expect((wrapper.get('[data-test="position-description-0"]').element as HTMLInputElement).value)
      .toBe("Away mission")

    await wrapper.get("form").trigger("submit")
    const body = await submitted(requests, "patch")
    const saved = body.positions_attributes.find((position: {id?: string}) => position.id === POSITION_ID)

    expect(saved._destroy).toBeUndefined()
    expect(saved.timer_ids).toEqual(["t1"])
  })

  // A project without a rate is still the project the rate comes from — the
  // next one that has one has to reach the row.
  it("fills the rate again after a project without one", async () => {
    const {wrapper} = await mountForm(`/invoices/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    await wrapper.get('[data-test="project"]').setValue(RATELESS_PROJECT_ID)
    await vi.waitFor(() => {
      expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("")
    })

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await vi.waitFor(() => {
      expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("50.0")
    })
  })

  // A saved row built from tracked time cannot follow the invoice to another
  // project — the server refuses that time — so it goes with the project it
  // came from, and the server is told to remove it.
  it("destroys a saved timer position when the project changes", async () => {
    const {wrapper, requests} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        projectId: PROJECT_ID,
        positions: [
          {id: POSITION_ID, description: "Away mission", hours: "2.0", rate: "90.0", value: "180.0", timerIds: ["t1"]},
        ],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await flushPromises()

    await wrapper.get("form").trigger("submit")
    const body = await submitted(requests, "patch")
    const generated = body.positions_attributes.find(
      (position: {id?: string}) => position.id === POSITION_ID,
    )

    expect(body.project_id).toBe(OTHER_PROJECT_ID)
    expect(generated._destroy).toBe(true)
    expect(generated.timer_ids).toEqual([])
  })

  // A failed load used to render an empty, editable form, which turned a read
  // error into a confusing save error later on.
  it("says so when the invoice cannot be loaded", async () => {
    const {wrapper} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {invoiceStatus: 500})

    await vi.waitFor(() => {
      expect(wrapper.find('[data-test="load-failed"]').exists()).toBe(true)
    })

    expect(wrapper.find("form").exists()).toBe(false)
  })

  it("marks a saved position for destruction rather than dropping it", async () => {
    const {wrapper, requests} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      invoice: {
        id: INVOICE_ID,
        projectId: PROJECT_ID,
        state: "created",
        date: "2026-03-01",
        ref: 1,
        positions: [{id: POSITION_ID, description: "Work", hours: "2.0", rate: "90.0", value: "180.0", timerIds: []}],
        editable: true,
        sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        createdAt: "",
        updatedAt: "",
      },
    })

    await wrapper.get('[data-test="position-remove-0"]').trigger("click")
    await wrapper.get('form').trigger("submit")

    const body = await submitted(requests, "patch")

    expect(body.positions_attributes[0]).toMatchObject({id: POSITION_ID, _destroy: true})
  })

  // Both guards lived in the ERB `new` action that this port removed.
  it("refuses a new invoice while the account has no address", async () => {
    const {wrapper} = await mountForm("/invoices/new", {account: {address: null}})

    expect(wrapper.find('[data-test="missing-address"]').exists()).toBe(true)
    expect(wrapper.find("form").exists()).toBe(false)
  })

  it("refuses a new invoice once the demo limit is reached", async () => {
    const {wrapper} = await mountForm("/invoices/new", {account: {invoiceLimitReached: true}})

    expect(wrapper.find('[data-test="limit-reached"]').exists()).toBe(true)
    expect(wrapper.find("form").exists()).toBe(false)
  })

  it("still edits an existing invoice when the limit is reached", async () => {
    const {wrapper} = await mountForm(`/invoices/${INVOICE_ID}/edit`, {
      account: {invoiceLimitReached: true},
      invoice: {id: INVOICE_ID, state: "created", positions: [], editable: true, sendable: false,
        abilities: {charge: true, pay: false, update: true, destroy: true, sendMail: false},
        createdAt: "", updatedAt: ""},
    })

    expect(wrapper.find('[data-test="limit-reached"]').exists()).toBe(false)
    expect(wrapper.find("form").exists()).toBe(true)
  })
})

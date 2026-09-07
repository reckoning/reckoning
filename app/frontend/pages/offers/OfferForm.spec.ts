import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import OfferForm from "./OfferForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const OFFER_ID = "cccccccc-0000-4000-8000-000000000001"
const PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000001"
const OTHER_PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000002"
const POSITION_ID = "eeeeeeee-0000-4000-8000-000000000001"
const RATELESS_PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000003"

// The schema calls `rate` nullable, so a client cannot assume a value.
const PROJECT_RATES: Record<string, string | null> = {
  [PROJECT_ID]: "90.0",
  [OTHER_PROJECT_ID]: "50.0",
  [RATELESS_PROJECT_ID]: null,
}

interface Options {
  offer?: Record<string, unknown>
  account?: Record<string, unknown>
  offerStatus?: number
}

function respond(requests: AxiosRequestConfig[], options: Options) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = {}

    if (url.includes("/account")) data = {id: "acc", name: "Enterprise", address: "Sector 001", ...options.account}
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
    } else if (url.includes("/offers")) data = options.offer ?? {}

    if (url.includes("/offers/") && options.offerStatus) {
      throw Object.assign(new Error(`Request failed with status ${options.offerStatus}`), {config})
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
      {path: "/offers", name: "offers", component: {template: "<div />"}},
      {path: "/offers/new", name: "offer-new", component: OfferForm},
      {path: "/offers/:id", name: "offer", component: {template: "<div />"}},
      {path: "/offers/:id/edit", name: "offer-edit", component: OfferForm},
    ],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(OfferForm, {
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

describe("OfferForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  // What the ERB recomputed on every keystroke — through `App.Offer`, whose
  // handlers were bound to the invoice form's field classes.
  it("fills the rate from the project and computes the value", async () => {
    const {wrapper} = await mountForm(`/offers/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("90.0")
    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("180")
  })

  // A row with no hours is a flat price, so its value stays typed by hand.
  it("keeps the value editable while there are no hours", async () => {
    const {wrapper} = await mountForm(`/offers/new?project_id=${PROJECT_ID}`)

    expect(wrapper.find('[data-test="position-value-0"]').exists()).toBe(true)
    expect(wrapper.find('[data-test="position-value-computed-0"]').exists()).toBe(false)
  })

  // What the ERB tracked as `oldProjectRate`.
  it("carries a rate it filled in over to the new project", async () => {
    const {wrapper} = await mountForm(`/offers/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

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
    const {wrapper} = await mountForm(`/offers/new?project_id=${PROJECT_ID}`)

    // Exactly the project's rate, but typed rather than filled in.
    await wrapper.get('[data-test="position-rate-0"]').setValue("90.0")
    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    await wrapper.get('[data-test="project"]').setValue(OTHER_PROJECT_ID)
    await flushPromises()
    await flushPromises()

    expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("90.0")
    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("180")
  })

  it("creates an offer with its positions", async () => {
    const {wrapper, requests} = await mountForm(`/offers/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="date"]').setValue("2026-08-01")
    await wrapper.get('[data-test="description"]').setValue("Sector survey")
    await wrapper.get('[data-test="position-description-0"]').setValue("Design")
    await wrapper.get('[data-test="position-hours-0"]').setValue("4")
    await flushPromises()

    await wrapper.get("form").trigger("submit")
    const body = await submitted(requests, "post")

    expect(body.project_id).toBe(PROJECT_ID)
    expect(body.date).toBe("2026-08-01")
    expect(body.description).toBe("Sector survey")
    expect(body.positions_attributes).toEqual([
      {description: "Design", hours: "4", rate: "90.0", value: "360"},
    ])
  })

  // The ERB form rendered the project select for `new` and `edit` alike, and
  // the API still takes a project change — the port had dropped it.
  it("offers the project on the edit form too", async () => {
    const {wrapper} = await mountForm(`/offers/${OFFER_ID}/edit`, {
      offer: {
        id: OFFER_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        abilities: {update: true, destroy: true, transitions: ["bid"]},
        projectId: PROJECT_ID,
        positions: [],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    expect(wrapper.find('[data-test="project"]').exists()).toBe(true)
  })

  // A blank rate is indistinguishable from a project that has none, which is
  // why the carry keys on the record rather than on the rate.
  it("clears a carried rate when the new project has none", async () => {
    const {wrapper} = await mountForm(`/offers/new?project_id=${PROJECT_ID}`)

    await wrapper.get('[data-test="position-hours-0"]').setValue("2")
    await flushPromises()

    await wrapper.get('[data-test="project"]').setValue(RATELESS_PROJECT_ID)

    await vi.waitFor(() => {
      expect((wrapper.get('[data-test="position-rate-0"]').element as HTMLInputElement).value).toBe("")
    })

    expect(wrapper.get('[data-test="position-value-computed-0"]').text()).toBe("")
  })

  // `belongs_to :project` is required. Offering "no project" on an existing
  // offer promised a clearing that the PATCH quietly dropped.
  it("offers no empty project on an existing offer", async () => {
    const {wrapper} = await mountForm(`/offers/${OFFER_ID}/edit`, {
      offer: {
        id: OFFER_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        abilities: {update: true, destroy: true, transitions: ["bid"]},
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

  // A project can be archived long after an offer was written against it, and
  // `GET /projects` answers with the active ones.
  it("keeps an archived project selectable on its own offer", async () => {
    const ARCHIVED = "aaaaaaaa-0000-4000-8000-000000000099"
    const {wrapper} = await mountForm(`/offers/${OFFER_ID}/edit`, {
      offer: {
        id: OFFER_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        abilities: {update: true, destroy: true, transitions: ["bid"]},
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

  it("marks a saved position for destruction rather than dropping it", async () => {
    const {wrapper, requests} = await mountForm(`/offers/${OFFER_ID}/edit`, {
      offer: {
        id: OFFER_ID,
        state: "created",
        date: "2026-03-01",
        editable: true,
        abilities: {update: true, destroy: true, transitions: ["bid"]},
        projectId: PROJECT_ID,
        positions: [{id: POSITION_ID, description: "Design", hours: "2.0", rate: "90.0", value: "180.0"}],
        createdAt: "2026-01-01T00:00:00Z",
        updatedAt: "2026-01-01T00:00:00Z",
      },
    })

    await wrapper.get('[data-test="position-remove-0"]').trigger("click")
    await wrapper.get("form").trigger("submit")

    const body = await submitted(requests, "patch")

    expect(body.positions_attributes).toEqual([
      {id: POSITION_ID, description: "Design", hours: "2.0", rate: "90.0", value: "180.0", _destroy: true},
    ])
  })

  // The offer's PDF carries the account address as the sender, and the model
  // refuses the create without one.
  it("asks for the account address before offering the form", async () => {
    const {wrapper} = await mountForm("/offers/new", {account: {address: ""}})

    expect(wrapper.find('[data-test="missing-address"]').exists()).toBe(true)
    expect(wrapper.find("form").exists()).toBe(false)
  })

  // A failed load would otherwise render an empty but editable form, turning
  // a read error into a confusing save error later on.
  it("says so when the offer cannot be loaded", async () => {
    const {wrapper} = await mountForm(`/offers/${OFFER_ID}/edit`, {offerStatus: 500})

    await vi.waitFor(() => {
      expect(wrapper.find('[data-test="load-failed"]').exists()).toBe(true)
    })

    expect(wrapper.find("form").exists()).toBe(false)
  })
})

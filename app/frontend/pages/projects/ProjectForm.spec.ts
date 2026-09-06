import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import ProjectForm from "./ProjectForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const PROJECT_ID = "aaaaaaaa-0000-4000-8000-000000000001"
const CUSTOMER_ID = "cccccccc-0000-4000-8000-000000000001"
const TASK_ID = "bbbbbbbb-0000-4000-8000-000000000001"

// One adapter for every endpoint the page touches: the project, the customer
// list and the account it checks for an address.
function respond(requests: AxiosRequestConfig[], account: {address: string | null}) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    const data = url.includes("/account")
      ? {id: "cccccccc-0000-4000-8000-000000000001", name: "Enterprise", ...account}
      : url.includes("/customers")
        ? [{id: CUSTOMER_ID, name: "Starfleet"}]
        : {
            id: PROJECT_ID,
            name: "Narendra 3",
            customerId: CUSTOMER_ID,
            roundUp: "900.0",
            workflowState: "active",
            rate: "90.0",
            tasks: [{id: TASK_ID, name: "Away mission", billable: true}],
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z",
          }

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }
}

async function mountForm(
  path: string,
  requests: AxiosRequestConfig[] = [],
  account: {address: string | null} = {address: "Sector 001"},
) {
  respond(requests, account)

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/projects", name: "projects", component: {template: "<div />"}},
      {path: "/projects/new", name: "project-new", component: ProjectForm},
      {path: "/projects/:id/edit", name: "project-edit", component: ProjectForm},
    ],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(ProjectForm, {
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

  return wrapper
}

async function submitted(requests: AxiosRequestConfig[], method: "post" | "patch") {
  return vi.waitFor(() => {
    const request = requests.find((entry) => entry.method?.toLowerCase() === method)
    expect(request).toBeTruthy()

    return JSON.parse(String(request?.data))
  })
}

describe("ProjectForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it("fills itself and its tasks from the record", async () => {
    const wrapper = await mountForm(`/projects/${PROJECT_ID}/edit`)

    expect((wrapper.get('[data-test="name"]').element as HTMLInputElement).value).toBe("Narendra 3")
    expect((wrapper.get('[data-test="task-name-0"]').element as HTMLInputElement).value).toBe("Away mission")
  })

  // `fields_for :tasks` deleted a row by sending `_destroy`, and the endpoint
  // still expects exactly that.
  it("marks a saved task for destruction rather than dropping it", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(`/projects/${PROJECT_ID}/edit`, requests)

    await wrapper.get('[data-test="task-remove-0"]').trigger("click")
    await wrapper.get("form").trigger("submit")

    const body = await submitted(requests, "patch")

    expect(body.tasks_attributes).toEqual([{id: TASK_ID, name: "Away mission", billable: true, _destroy: true}])
  })

  it("just forgets a task that was never saved", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(`/projects/${PROJECT_ID}/edit`, requests)

    await wrapper.get('[data-test="add-task"]').trigger("click")
    await wrapper.get('[data-test="task-name-1"]').setValue("Shore leave")
    await wrapper.get('[data-test="task-remove-1"]').trigger("click")
    await wrapper.get("form").trigger("submit")

    const body = await submitted(requests, "patch")

    expect(body.tasks_attributes).toEqual([{id: TASK_ID, name: "Away mission", billable: true}])
  })

  // The columns are NOT NULL with a 0.0 default, so a blank is not a null —
  // it means "leave it as it is", and the key stays out of the body.
  it("leaves an untouched decimal out of the request", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm("/projects/new", requests)

    await wrapper.get('[data-test="customer"]').setValue(CUSTOMER_ID)
    await wrapper.get('[data-test="name"]').setValue("Wolf 359")
    await wrapper.get("form").trigger("submit")

    const body = await submitted(requests, "post")

    expect(body.name).toBe("Wolf 359")
    expect("budget" in body).toBe(false)
  })

  // `belongs_to :customer` is required, so the server would refuse it anyway —
  // the point is that the form says so instead of doing nothing.
  it("says a customer is missing rather than swallowing the submit", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm("/projects/new", requests)

    await wrapper.get('[data-test="name"]').setValue("Wolf 359")
    await wrapper.get("form").trigger("submit")

    await vi.waitFor(() => {
      expect(wrapper.find('[data-test="customer-error"]').exists()).toBe(true)
    })
    expect(requests.some((entry) => entry.method?.toLowerCase() === "post")).toBe(false)
  })

  // A raw <select> in the ERB form, and it decides how tracked time is
  // rounded when it gets billed.
  it("carries the rounding interval", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(`/projects/${PROJECT_ID}/edit`, requests)

    expect((wrapper.get('[data-test="round-up"]').element as HTMLSelectElement).value).toBe("900")

    await wrapper.get('[data-test="round-up"]').setValue("1800")
    await wrapper.get("form").trigger("submit")

    const body = await submitted(requests, "patch")

    expect(body.round_up).toBe("1800")
  })

  it("deletes the project after a confirm", async () => {
    vi.stubGlobal("confirm", vi.fn(() => true))
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(`/projects/${PROJECT_ID}/edit`, requests)

    await wrapper.get('[data-test="delete"]').trigger("click")

    await vi.waitFor(() => {
      expect(requests.some((entry) => entry.method?.toLowerCase() === "delete")).toBe(true)
    })
  })

  it("offers no delete while the project does not exist yet", async () => {
    const wrapper = await mountForm("/projects/new")

    expect(wrapper.find('[data-test="delete"]').exists()).toBe(false)
  })

  // The ERB `new` action refused to render without an account address.
  it("refuses a new project while the account has no address", async () => {
    const wrapper = await mountForm("/projects/new", [], {address: null})

    expect(wrapper.find('[data-test="missing-address"]').exists()).toBe(true)
    expect(wrapper.find("form").exists()).toBe(false)
  })

  it("still edits an existing project when the address is missing", async () => {
    const wrapper = await mountForm(`/projects/${PROJECT_ID}/edit`, [], {address: null})

    expect(wrapper.find('[data-test="missing-address"]').exists()).toBe(false)
    expect(wrapper.find("form").exists()).toBe(true)
  })
})

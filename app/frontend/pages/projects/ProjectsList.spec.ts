import {describe, it, expect, afterEach, vi} from "vitest"
import {RouterLinkStub, flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import type {AxiosRequestConfig} from "axios"
import ProjectsList from "./ProjectsList.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"
import type {Project} from "@/services/api/models"

function project(overrides: Partial<Project> = {}): Project {
  return {
    id: "aaaaaaaa-0000-4000-8000-000000000001",
    name: "Narendra 3",
    workflowState: "active",
    customerId: "cccccccc-0000-4000-8000-000000000001",
    customerName: "Starfleet",
    tasks: [],
    timerValues: "12.5",
    budget: "1000.0",
    budgetPercent: "40.0",
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
    ...overrides,
  } as Project
}

function mountList(records: Project[], requests: AxiosRequestConfig[] = []) {
  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    return {data: records, status: 200, statusText: "OK", headers: {}, config}
  }

  return mount(ProjectsList, {
    global: {
      plugins: [
        [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
        i18n,
        createPinia(),
      ],
      stubs: {RouterLink: RouterLinkStub},
    },
  })
}

describe("ProjectsList", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  // The ERB list was grouped by customer, and a project without one still had
  // to appear somewhere.
  it("groups by customer and keeps the customerless together", async () => {
    const wrapper = mountList([
      project(),
      project({
        id: "aaaaaaaa-0000-4000-8000-000000000002",
        name: "Wolf 359",
        customerId: "cccccccc-0000-4000-8000-000000000002",
        customerName: "Klingon",
      }),
      project({
        id: "aaaaaaaa-0000-4000-8000-000000000003",
        name: "Utopia",
        customerId: null,
        customerName: null,
      }),
    ])
    await flushPromises()

    const headings = wrapper.findAll("section h2").map((node) => node.text())

    // happy-dom has no <html lang>, so the i18n plugin falls back to English.
    expect(headings).toEqual(["Klingon", "Starfleet", "Without a customer"])
  })

  // Nothing stops two customers of one account from sharing a name.
  it("keeps two customers of the same name apart", async () => {
    const wrapper = mountList([
      project(),
      project({
        id: "aaaaaaaa-0000-4000-8000-000000000004",
        name: "Wolf 359",
        customerId: "cccccccc-0000-4000-8000-000000000009",
        customerName: "Starfleet",
      }),
    ])
    await flushPromises()

    expect(wrapper.findAll("section")).toHaveLength(2)
  })

  it("asks the API for the archived ones when the filter flips", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = mountList([project()], requests)
    await flushPromises()

    await wrapper.get('[data-test="filter-archived"]').trigger("click")
    await flushPromises()

    await vi.waitFor(() => {
      expect(requests.some((request) => request.params?.state === "archived")).toBe(true)
    })
  })

  // The bar is capped so an overrun does not run off the row; the hours beside
  // it still say what really happened.
  it("caps the progress bar at full", async () => {
    const wrapper = mountList([project({budgetPercent: "180.0"})])
    await flushPromises()

    const bar = wrapper.get('[data-test="progress-aaaaaaaa-0000-4000-8000-000000000001"]')

    expect(bar.attributes("style")).toContain("width: 100%")
  })

  it("archives through the endpoint after a confirm", async () => {
    vi.stubGlobal("confirm", vi.fn(() => true))
    const requests: AxiosRequestConfig[] = []
    const wrapper = mountList([project()], requests)
    await flushPromises()

    await wrapper.get('[data-test="archive-aaaaaaaa-0000-4000-8000-000000000001"]').trigger("click")

    await vi.waitFor(() => {
      expect(
        requests.some((request) => String(request.url).includes("/archive")),
      ).toBe(true)
    })
  })

  it("leaves the project alone when the confirm is declined", async () => {
    vi.stubGlobal("confirm", vi.fn(() => false))
    const requests: AxiosRequestConfig[] = []
    const wrapper = mountList([project()], requests)
    await flushPromises()

    await wrapper.get('[data-test="archive-aaaaaaaa-0000-4000-8000-000000000001"]').trigger("click")
    await flushPromises()

    expect(requests.some((request) => String(request.url).includes("/archive"))).toBe(false)
  })
})

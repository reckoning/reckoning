import {describe, it, expect, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import type {AxiosAdapter} from "axios"
import CustomersList from "./CustomersList.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import type {Customer} from "@/services/api/models"

// Swap only the transport so the mutator, vue-query and the generated
// service all stay on the real code path.
function stubTransport(respond: AxiosAdapter) {
  AXIOS_INSTANCE.defaults.adapter = respond
}

function customer(overrides: Partial<Customer> = {}): Customer {
  return {
    id: "5a3f0b1c-0000-4000-8000-000000000001",
    name: "Starfleet",
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
    ...overrides,
  }
}

function mountList() {
  return mount(CustomersList, {
    global: {
      plugins: [[VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}]],
    },
  })
}

describe("CustomersList", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  it("renders the names the API returns", async () => {
    stubTransport(async (config) => ({
      data: [customer(), customer({id: "5a3f0b1c-0000-4000-8000-000000000002", name: "Klingon"})],
      status: 200,
      statusText: "OK",
      headers: {},
      config,
    }))

    const wrapper = mountList()
    await flushPromises()

    expect(wrapper.get('[data-test="customers"]').text()).toContain("Starfleet")
    expect(wrapper.get('[data-test="customers"]').text()).toContain("Klingon")
  })

  it("shows an error state when the request fails", async () => {
    stubTransport(async () => {
      throw new Error("boom")
    })

    const wrapper = mountList()
    await flushPromises()

    expect(wrapper.find('[data-test="error"]').exists()).toBe(true)
  })
})

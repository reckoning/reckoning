import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createRouter, createMemoryHistory} from "vue-router"
import type {AxiosAdapter, AxiosRequestConfig} from "axios"
import CustomerForm from "./CustomerForm.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"
import type {Customer} from "@/services/api/models"

// Swap only the transport, so the mutator, vue-query and the generated
// service stay on the real code path.
function stubTransport(respond: AxiosAdapter) {
  AXIOS_INSTANCE.defaults.adapter = respond
}

const record: Customer = {
  id: "5a3f0b1c-0000-4000-8000-000000000001",
  name: "Starfleet",
  email: "ops@star.fleet",
  paymentDue: 14,
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

function router() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/customers", name: "customers", component: {template: "<div />"}},
      {path: "/customers/:id/edit", name: "customer-edit", component: CustomerForm},
    ],
  })
}

async function mountForm(requests: AxiosRequestConfig[] = []) {
  stubTransport(async (config) => {
    requests.push(config)

    return {data: record, status: 200, statusText: "OK", headers: {}, config}
  })

  const routerInstance = router()
  await routerInstance.push(`/customers/${record.id}/edit`)
  await routerInstance.isReady()

  const wrapper = mount(CustomerForm, {
    global: {
      plugins: [
        [VueQueryPlugin, {queryClientConfig: {defaultOptions: {queries: {retry: false}}}}],
        i18n,
        createPinia(),
        routerInstance,
      ],
    },
  })

  await flushPromises()

  return wrapper
}

describe("CustomerForm", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("fills the form from the record", async () => {
    const wrapper = await mountForm()

    expect((wrapper.get('[data-test="name"]').element as HTMLInputElement).value).toBe("Starfleet")
    expect((wrapper.get('[data-test="email"]').element as HTMLInputElement).value).toBe("ops@star.fleet")
    expect((wrapper.get('[data-test="payment-due"]').element as HTMLInputElement).value).toBe("14")
  })

  it("sends the edited values", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(requests)

    await wrapper.get('[data-test="name"]').setValue("Starfleet Command")
    await wrapper.get('form').trigger("submit")

    // Validation is async, so the request is a few microtasks behind the
    // submit — asserting straight after it reads an empty list and lets the
    // real call escape into the afterEach.
    const update = await vi.waitFor(() => {
      const request = requests.find((entry) => entry.method?.toLowerCase() === "patch")
      expect(request).toBeTruthy()

      return request
    })

    expect(JSON.parse(String(update?.data)).name).toBe("Starfleet Command")
  })

  it("refuses to send an empty name", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(requests)

    await wrapper.get('[data-test="name"]').setValue("")
    await wrapper.get('form').trigger("submit")

    await vi.waitFor(() => {
      expect(wrapper.find('[data-test="name-error"]').exists()).toBe(true)
    })
    expect(requests.some((request) => request.method?.toLowerCase() === "patch")).toBe(false)
  })

  it("appends a template token rather than replacing the text", async () => {
    const wrapper = await mountForm()

    await wrapper.get('[data-test="tab-email"]').trigger("click")
    await wrapper.get('[data-test="email-template"]').setValue("Hallo ")
    await wrapper.get('[data-test="token-company"]').trigger("click")
    await flushPromises()

    expect((wrapper.get('[data-test="email-template"]').element as HTMLTextAreaElement).value)
      .toBe("Hallo {company}")
  })

  // Only the four the invoice mailer substitutes; anything else would reach
  // the customer verbatim.
  it("offers exactly the tokens the mailer understands", async () => {
    const wrapper = await mountForm()

    await wrapper.get('[data-test="tab-email"]').trigger("click")

    const offered = wrapper
      .findAll('[data-test="template-tokens"] code')
      .map((node) => node.text())

    expect(offered).toEqual(["{date}", "{month}", "{project}", "{company}"])
  })

  // "" coerces to 0, and a payment period of zero is not an empty one — it
  // makes every new invoice due on the spot.
  it("clears a number instead of sending zero", async () => {
    const requests: AxiosRequestConfig[] = []
    const wrapper = await mountForm(requests)

    await wrapper.get('[data-test="payment-due"]').setValue("")
    await wrapper.get('form').trigger("submit")

    const update = await vi.waitFor(() => {
      const request = requests.find((entry) => entry.method?.toLowerCase() === "patch")
      expect(request).toBeTruthy()

      return request
    })

    expect(JSON.parse(String(update?.data)).paymentDue).toBeNull()
  })
})

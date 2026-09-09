import {describe, it, expect, afterEach, vi} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import AccountSettings from "./AccountSettings.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const ACCOUNT = {
  id: "eeeeeeee-0000-4000-8000-000000000001",
  name: "Enterprise",
  subdomain: "enterprise",
  address: "1 Starfleet Way",
  country: "US",
  telefon: "+1 555",
  fax: null,
  publicEmail: "hello@star.fleet",
  website: "star.fleet",
  officeSpace: 100,
  deductibleOfficeSpace: 20,
  bank: "Bank of Bolias",
  iban: "DE00",
  bic: "BOLIAS",
  vatId: "DE123",
  tax: "19.0",
  provision: "10.0",
  signature: "Regards",
  offerHeadline: "Our offer",
  createdAt: "2026-01-01T00:00:00Z",
  updatedAt: "2026-01-01T00:00:00Z",
}

async function mountSettings(path = "/account") {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    return {data: ACCOUNT, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{path: "/account", name: "account-settings", component: AccountSettings}],
  })
  await router.push(path)
  await router.isReady()

  const wrapper = mount(AccountSettings, {
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

async function saved(requests: AxiosRequestConfig[]) {
  return vi.waitFor(() => {
    const call = requests.find((entry) => entry.method?.toLowerCase() === "patch")
    expect(call).toBeTruthy()

    return JSON.parse(String(call?.data))
  })
}

describe("AccountSettings", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
    vi.restoreAllMocks()
  })

  it("opens on the first section with the account filled in", async () => {
    const {wrapper} = await mountSettings()

    expect(wrapper.find('[data-test="section-basic"]').exists()).toBe(true)
    expect((wrapper.get('[data-test="name"]').element as HTMLInputElement).value).toBe("Enterprise")
    expect((wrapper.get('[data-test="subdomain"]').element as HTMLInputElement).value).toBe(
      "enterprise",
    )
  })

  it("lists every section the server-rendered screen had", async () => {
    const {wrapper} = await mountSettings()

    for (const section of ["basic", "address", "banking", "taxes", "mailing", "offer"]) {
      expect(wrapper.find(`[data-test="section-link-${section}"]`).exists()).toBe(true)
    }
  })

  // The section is the hash, so a link into one of them keeps working.
  it("opens the section the hash names", async () => {
    const {wrapper} = await mountSettings("/account#banking")

    expect(wrapper.find('[data-test="section-banking"]').exists()).toBe(true)
    expect((wrapper.get('[data-test="iban"]').element as HTMLInputElement).value).toBe("DE00")
  })

  it("puts the section it switches to in the url", async () => {
    const {wrapper, router} = await mountSettings()

    await wrapper.get('[data-test="section-link-taxes"]').trigger("click")

    await vi.waitFor(() => {
      expect(router.currentRoute.value.hash).toBe("#taxes")
      expect(wrapper.find('[data-test="section-taxes"]').exists()).toBe(true)
    })
  })

  // Each section saves what it shows, the way each of the six partials
  // carried its own submit.
  it("sends only the fields of the section that was saved", async () => {
    const {wrapper, requests} = await mountSettings("/account#banking")

    await wrapper.get('[data-test="bank"]').setValue("Bank of Bolias II")
    await wrapper.get("form").trigger("submit")

    expect(await saved(requests)).toEqual({
      bank: "Bank of Bolias II",
      iban: "DE00",
      bic: "BOLIAS",
    })
  })

  it("sends the address section with its numbers as numbers", async () => {
    const {wrapper, requests} = await mountSettings("/account#address")

    await wrapper.get('[data-test="office-space"]').setValue("120")
    await wrapper.get("form").trigger("submit")

    const body = await saved(requests)

    expect(body.officeSpace).toBe(120)
    expect(body.deductibleOfficeSpace).toBe(20)
    expect(body.address).toBe("1 Starfleet Way")
  })

  // Blank is "not entered", not an office of no size — the deductible share
  // is worked out from both, and an expense of that kind deducts nothing
  // until they are there.
  it("sends a cleared space as nothing rather than as zero", async () => {
    const {wrapper, requests} = await mountSettings("/account#address")

    await wrapper.get('[data-test="deductible-office-space"]').setValue("")
    await wrapper.get("form").trigger("submit")

    expect((await saved(requests)).deductibleOfficeSpace).toBeNull()
  })

  it("saves the signature on its own", async () => {
    const {wrapper, requests} = await mountSettings("/account#mailing")

    await wrapper.get('[data-test="signature"]').setValue("Kind regards")
    await wrapper.get("form").trigger("submit")

    expect(await saved(requests)).toEqual({signature: "Kind regards"})
  })

  it("prints the domain the subdomain sits under", async () => {
    const {wrapper} = await mountSettings()

    expect(wrapper.get('[data-test="section-basic"]').text()).toContain(".")
  })
})

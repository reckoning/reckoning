import {describe, it, expect} from "vitest"
import {mount} from "@vue/test-utils"
import {createMemoryHistory, createRouter} from "vue-router"
import LegalPage from "./LegalPage.vue"
import {legalDocument} from "@/content/legal"
import {i18n} from "@/plugins/i18n"

async function mountPage(document: string) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{path: "/", name: "dashboard", component: {template: "<div />"}}],
  })

  await router.push("/")
  await router.isReady()

  return mount(LegalPage, {props: {document}, global: {plugins: [i18n, router]}})
}

describe("LegalPage", () => {
  it("renders every section of the document it is given", async () => {
    const wrapper = await mountPage("impressum")
    const doc = legalDocument("impressum", "en")

    expect(wrapper.get("h1").text()).toContain(doc.title)
    expect(wrapper.findAll("h2")).toHaveLength(doc.sections.length)
  })

  // The three documents are separate pages, not one page with a heading swap.
  it.each(["impressum", "privacy", "terms"])("renders %s", async (name) => {
    const wrapper = await mountPage(name)

    expect(wrapper.get(`[data-test="legal-${name}"]`).text()).toContain(
      legalDocument(name, "en").title,
    )
  })

  it("prints the rows a section lists as terms", async () => {
    const wrapper = await mountPage("privacy")

    expect(wrapper.findAll("dt").length).toBeGreaterThan(0)
    expect(wrapper.text()).toContain("Server logs")
  })

  // German is the text that binds; English is offered as a reading aid.
  it("answers in both languages", () => {
    expect(legalDocument("terms", "de").title).toBe("Allgemeine Geschäftsbedingungen")
    expect(legalDocument("terms", "en").title).toBe("Terms of service")
    expect(legalDocument("terms", "fr").title).toBe("Allgemeine Geschäftsbedingungen")
  })
})

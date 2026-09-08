import {describe, it, expect, vi, beforeEach, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {QueryClient, VueQueryPlugin} from "@tanstack/vue-query"
import {createMemoryHistory, createRouter} from "vue-router"
import AppProgress from "./AppProgress.vue"

function mountBar() {
  const queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{path: "/", name: "home", component: {template: "<div />"}}],
  })

  const wrapper = mount(AppProgress, {
    global: {plugins: [[VueQueryPlugin, {queryClient}], router]},
  })

  return {wrapper, queryClient}
}

const bar = '[data-test="loading-bar"]'

describe("AppProgress", () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => vi.useRealTimers())

  it("shows nothing while nothing is in flight", async () => {
    const {wrapper} = mountBar()

    await flushPromises()

    expect(wrapper.find(bar).exists()).toBe(false)
  })

  // Turbo holds the bar back for half a second, so a request that answers
  // quickly never makes it flash.
  it("stays away for a request that answers inside the delay", async () => {
    const {wrapper, queryClient} = mountBar()

    let answer: (value: string) => void = () => {}
    queryClient.fetchQuery({
      queryKey: ["quick"],
      queryFn: () => new Promise<string>((resolve) => (answer = resolve)),
    })
    await flushPromises()

    vi.advanceTimersByTime(400)
    answer("done")
    await flushPromises()

    vi.advanceTimersByTime(400)
    await flushPromises()

    expect(wrapper.find(bar).exists()).toBe(false)
  })

  it("appears once a request outlasts the delay, and grows while it runs", async () => {
    const {wrapper, queryClient} = mountBar()

    queryClient.fetchQuery({queryKey: ["slow"], queryFn: () => new Promise<string>(() => {})})
    await flushPromises()

    vi.advanceTimersByTime(500)
    await flushPromises()

    expect(wrapper.find(bar).exists()).toBe(true)
    const first = wrapper.get(bar).attributes("style")

    vi.advanceTimersByTime(900)
    await flushPromises()

    expect(wrapper.get(bar).attributes("style")).not.toBe(first)
  })

  it("runs to the end and leaves once the request is done", async () => {
    const {wrapper, queryClient} = mountBar()

    let answer: (value: string) => void = () => {}
    queryClient.fetchQuery({
      queryKey: ["slow"],
      queryFn: () => new Promise<string>((resolve) => (answer = resolve)),
    })
    await flushPromises()

    vi.advanceTimersByTime(500)
    await flushPromises()
    expect(wrapper.find(bar).exists()).toBe(true)

    answer("done")
    await flushPromises()

    expect(wrapper.get(bar).attributes("style")).toContain("width: 100%")

    vi.advanceTimersByTime(300)
    await flushPromises()

    expect(wrapper.find(bar).exists()).toBe(false)
  })
})

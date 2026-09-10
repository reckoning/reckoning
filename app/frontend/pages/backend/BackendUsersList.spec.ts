import {describe, it, expect, afterEach} from "vitest"
import {flushPromises, mount} from "@vue/test-utils"
import {VueQueryPlugin} from "@tanstack/vue-query"
import {createPinia} from "pinia"
import {createMemoryHistory, createRouter} from "vue-router"
import type {AxiosRequestConfig} from "axios"
import BackendUsersList from "./BackendUsersList.vue"
import {AXIOS_INSTANCE} from "@/services/axiosClient"
import {i18n} from "@/plugins/i18n"

const USERS = [
  {
    id: "11111111-0000-4000-8000-000000000001",
    email: "data@star.fleet",
    name: "Data",
    admin: false,
    enabled: true,
    confirmed: false,
    accountId: "aaaaaaaa-0000-4000-8000-000000000001",
    currentSignInAt: null,
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
  },
  {
    id: "11111111-0000-4000-8000-000000000002",
    email: "worf@star.fleet",
    name: "Worf",
    admin: true,
    enabled: true,
    confirmed: true,
    accountId: "aaaaaaaa-0000-4000-8000-000000000001",
    currentSignInAt: "2026-03-04T10:00:00Z",
    createdAt: "2026-02-01T00:00:00Z",
    updatedAt: "2026-02-01T00:00:00Z",
  },
]

interface Options {
  path?: string
  users?: unknown[]
  usersCount?: number
}

async function mountList(options: Options = {}) {
  const requests: AxiosRequestConfig[] = []

  AXIOS_INSTANCE.defaults.adapter = async (config) => {
    requests.push(config)

    const url = String(config.url)
    let data: unknown = {}

    if (url.includes("/stats")) {
      data = {usersCount: options.usersCount ?? 2, accountsCount: 1}
    } else if (url.includes("/users")) {
      data = options.users ?? USERS
    }

    return {data, status: 200, statusText: "OK", headers: {}, config}
  }

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {path: "/backend", name: "backend", component: {template: "<div />"}},
      {path: "/backend/users", name: "backend-users", component: BackendUsersList},
      {path: "/backend/users/new", name: "backend-user-new", component: {template: "<div />"}},
      {
        path: "/backend/users/:id/edit",
        name: "backend-user-edit",
        component: {template: "<div />"},
      },
    ],
  })

  await router.push(options.path ?? "/backend/users")
  await router.isReady()

  const wrapper = mount(BackendUsersList, {
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

describe("BackendUsersList", () => {
  afterEach(() => {
    delete AXIOS_INSTANCE.defaults.adapter
  })

  it("lists every account's users with what the table shows", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.findAll('[data-test="users"] tbody tr')).toHaveLength(2)
    expect(wrapper.get(`[data-test="user-${USERS[0].id}"]`).text()).toContain("data@star.fleet")
    // Never signed in, rather than an empty cell.
    expect(wrapper.get(`[data-test="user-${USERS[0].id}"]`).text()).toContain("never")
    expect(wrapper.get(`[data-test="user-${USERS[1].id}"]`).text()).toContain("Yes")
  })

  // The confirmation mail is the only way into an account an admin created,
  // and offering it for a user who already confirmed would do nothing.
  it("offers the welcome mail only where it is still needed", async () => {
    const {wrapper} = await mountList()

    expect(wrapper.find(`[data-test="welcome-${USERS[0].id}"]`).exists()).toBe(true)
    expect(wrapper.find(`[data-test="welcome-${USERS[1].id}"]`).exists()).toBe(false)
  })

  it("puts the sort in the url and asks the endpoint for it", async () => {
    const {wrapper, router, requests} = await mountList()

    await wrapper.get('[data-test="sort-email"]').trigger("click")
    await flushPromises()

    expect(router.currentRoute.value.query).toMatchObject({sort: "email", direction: "desc"})
    expect(
      requests.some((entry) => String(entry.url).includes("/users") && entry.params?.sort === "email"),
    ).toBe(true)
  })

  // Clicking the column you are already sorted by turns it around.
  it("flips the direction on the column it is sorted by", async () => {
    const {wrapper, router} = await mountList({path: "/backend/users?sort=email&direction=desc"})

    await wrapper.get('[data-test="sort-email"]').trigger("click")
    await flushPromises()

    expect(router.currentRoute.value.query.direction).toBe("asc")
  })

  // The count decides it: a full last page would otherwise offer a next one
  // that is empty.
  it("offers a next page only while there is one", async () => {
    const {wrapper} = await mountList({usersCount: 2})

    expect(wrapper.get('[data-test="next-page"]').attributes("disabled")).toBeDefined()

    const more = await mountList({usersCount: 40})

    expect(more.wrapper.get('[data-test="next-page"]').attributes("disabled")).toBeUndefined()
  })

  it("says so when there is nobody", async () => {
    const {wrapper} = await mountList({users: [], usersCount: 0})

    expect(wrapper.find('[data-test="empty"]').exists()).toBe(true)
  })
})

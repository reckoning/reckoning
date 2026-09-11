<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useQueryClient } from "@tanstack/vue-query"
import {
  useBackendUsers,
  useBackendStats,
  useDestroyBackendUser,
  useSendWelcomeBackendUser,
  getBackendUsersQueryKey,
  getBackendStatsQueryKey,
} from "@/services/api/services/backend/backend"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import UiButton from "@/components/ui/UiButton.vue"
import UiPagination from "@/components/ui/UiPagination.vue"
import UiPanel from "@/components/ui/UiPanel.vue"
import UiSortHeader from "@/components/ui/UiSortHeader.vue"

// `backend/users/index`: every user of every account, twenty to a page, with
// the columns the server-rendered table sorted by.
const PER_PAGE = 20

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()
const queryClient = useQueryClient()

function queryValue(key: string): string {
  const raw = route.query[key]

  return typeof raw === "string" ? raw : ""
}

const page = computed(() => Math.max(1, Number(queryValue("page")) || 1))
const sort = computed(() => queryValue("sort"))
const direction = computed(() => (queryValue("direction") === "asc" ? "asc" : "desc"))

const params = computed(() => {
  const query: Record<string, string | number> = { page: page.value, perPage: PER_PAGE }

  if (sort.value) {
    query.sort = sort.value
    query.direction = direction.value
  }

  return query
})

const { data: users, isPending, isError } = useBackendUsers(params)
const { data: stats } = useBackendStats()
const { mutateAsync: destroy } = useDestroyBackendUser()
const { mutateAsync: sendWelcome } = useSendWelcomeBackendUser()

const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, { dateStyle: "medium", timeStyle: "short" }),
)

function moment(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(value)) : t("backend.never")
}

// The count answers the next page: the client cannot read the Link header
// through the generated mutator.
const hasNextPage = computed(() => page.value * PER_PAGE < (stats.value?.usersCount ?? 0))

function go(changes: Record<string, string | number | undefined>): void {
  const query: Record<string, string> = {}

  for (const [key, value] of Object.entries({ ...route.query, ...changes })) {
    if (typeof value === "string" && value !== "") query[key] = value
    if (typeof value === "number") query[key] = String(value)
  }

  router.push({ query })
}

function sortBy(column: string): void {
  const flip = sort.value === column && direction.value === "desc" ? "asc" : "desc"

  go({ sort: column, direction: flip, page: undefined })
}

async function refresh(): Promise<void> {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: getBackendUsersQueryKey() }),
    queryClient.invalidateQueries({ queryKey: getBackendStatsQueryKey() }),
  ])
}

async function onSendWelcome(id: string): Promise<void> {
  try {
    await sendWelcome({ id })
    toasts.push("success", t("backend.welcomeSent"))
  } catch {
    toasts.push("error", t("backend.welcomeFailed"))
  }
}

async function onDestroy(id: string): Promise<void> {
  if (!(await confirmDialog(t("backend.confirmDeleteUser")))) return

  try {
    await destroy({ id })
    toasts.push("success", t("backend.userDeleted"))
    await refresh()
  } catch {
    toasts.push("error", t("backend.userDeleteFailed"))
  }
}
</script>

<template>
  <div id="backend-users">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="users-title">{{ t("backend.users.title") }}</h1>

      <div class="flex flex-wrap gap-2">
        <RouterLink v-slot="{ href, navigate }" :to="{ name: 'backend' }" custom>
          <UiButton as="a" :href="href" data-test="back" @click="navigate">
            {{ t("backend.back") }}
          </UiButton>
        </RouterLink>
        <RouterLink v-slot="{ href, navigate }" :to="{ name: 'backend-user-new' }" custom>
          <UiButton as="a" variant="primary" :href="href" data-test="new-user" @click="navigate">
            {{ t("backend.users.new") }}
          </UiButton>
        </RouterLink>
      </div>
    </div>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("backend.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("backend.loadFailed") }}</p>

    <UiPanel v-else class="mt-4" data-test="users">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="border-b-2 border-rule-strong text-left">
              <th class="p-2">
                <UiSortHeader
                  column="email"
                  :label="t('backend.columns.email')"
                  :sort="sort"
                  :direction="direction"
                  @sort="sortBy"
                />
              </th>
              <th class="p-2">
                <UiSortHeader
                  column="current_sign_in_at"
                  :label="t('backend.columns.currentSignInAt')"
                  :sort="sort"
                  :direction="direction"
                  @sort="sortBy"
                />
              </th>
              <th class="p-2">
                <UiSortHeader
                  column="created_at"
                  :label="t('backend.columns.createdAt')"
                  :sort="sort"
                  :direction="direction"
                  @sort="sortBy"
                />
              </th>
              <th class="p-2">
                <UiSortHeader
                  column="admin"
                  :label="t('backend.columns.admin')"
                  :sort="sort"
                  :direction="direction"
                  @sort="sortBy"
                />
              </th>
              <th class="p-2 text-right">{{ t("backend.columns.actions") }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="user in users ?? []"
              :key="user.id"
              class="border-b border-rule odd:bg-surface-stripe"
              :data-test="`user-${user.id}`"
            >
              <td class="p-2">{{ user.email }}</td>
              <td class="p-2 whitespace-nowrap">{{ moment(user.currentSignInAt) }}</td>
              <td class="p-2 whitespace-nowrap">{{ moment(user.createdAt) }}</td>
              <td class="p-2">{{ user.admin ? t("backend.yes") : t("backend.no") }}</td>
              <td class="p-2">
                <div class="bs-btn-group justify-end">
                  <RouterLink
                    v-slot="{ href, navigate }"
                    :to="{ name: 'backend-user-edit', params: { id: user.id } }"
                    custom
                  >
                    <UiButton
                      as="a"
                      size="small"
                      :href="href"
                      :title="t('backend.edit')"
                      :data-test="`edit-${user.id}`"
                      @click="navigate"
                    >
                      <i class="fa fa-edit"></i>
                    </UiButton>
                  </RouterLink>

                  <UiButton
                    v-if="!user.confirmed"
                    size="small"
                    :title="t('backend.sendWelcome')"
                    :data-test="`welcome-${user.id}`"
                    @click="onSendWelcome(user.id)"
                  >
                    <i class="fa fa-paper-plane"></i>
                  </UiButton>

                  <UiButton
                    size="small"
                    variant="danger"
                    :title="t('backend.delete')"
                    :data-test="`destroy-${user.id}`"
                    @click="onDestroy(user.id)"
                  >
                    <i class="fa fa-trash"></i>
                  </UiButton>
                </div>
              </td>
            </tr>

            <tr v-if="(users?.length ?? 0) === 0">
              <td class="p-2 text-muted" colspan="5" data-test="empty">
                {{ t("backend.users.empty") }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </UiPanel>

    <UiPagination
      :page="page"
      :has-next="hasNextPage"
      :previous-label="t('backend.previous')"
      :next-label="t('backend.next')"
      @go="go({ page: $event })"
    />
  </div>
</template>

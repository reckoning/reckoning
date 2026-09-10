<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useBackendAccounts, useBackendStats } from "@/services/api/services/backend/backend"
import UiButton from "@/components/ui/UiButton.vue"
import UiPagination from "@/components/ui/UiPagination.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

// `backend/accounts/index`: every account, twenty to a page. The
// server-rendered list showed the name alone; the plan, the two feature flags
// and how many people are on it are what an admin came here to look at.
const PER_PAGE = 20

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

const page = computed(() => {
  const raw = route.query.page

  return Math.max(1, Number(typeof raw === "string" ? raw : "") || 1)
})

const params = computed(() => ({ page: page.value, perPage: PER_PAGE }))

const { data: accounts, isPending, isError } = useBackendAccounts(params)
const { data: stats } = useBackendStats()

const dates = computed(() => new Intl.DateTimeFormat(locale.value, { dateStyle: "medium" }))

const hasNextPage = computed(() => page.value * PER_PAGE < (stats.value?.accountsCount ?? 0))

function features(account: {featureExpenses?: boolean; featureLogbook?: boolean}): string {
  const on = [
    account.featureExpenses ? t("backend.accounts.expenses") : null,
    account.featureLogbook ? t("backend.accounts.logbook") : null,
  ].filter(Boolean)

  return on.length > 0 ? on.join(", ") : "—"
}
</script>

<template>
  <div id="backend-accounts">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="accounts-title">{{ t("backend.accounts.title") }}</h1>

      <div class="flex flex-wrap gap-2">
        <RouterLink v-slot="{ href, navigate }" :to="{ name: 'backend' }" custom>
          <UiButton as="a" :href="href" data-test="back" @click="navigate">
            {{ t("backend.back") }}
          </UiButton>
        </RouterLink>
        <RouterLink v-slot="{ href, navigate }" :to="{ name: 'backend-account-new' }" custom>
          <UiButton as="a" variant="primary" :href="href" data-test="new-account" @click="navigate">
            {{ t("backend.accounts.new") }}
          </UiButton>
        </RouterLink>
      </div>
    </div>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("backend.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("backend.loadFailed") }}</p>

    <UiPanel v-else class="mt-4" data-test="accounts">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="border-b-2 border-rule-strong text-left">
              <th class="p-2">{{ t("backend.columns.name") }}</th>
              <th class="p-2">{{ t("backend.columns.plan") }}</th>
              <th class="p-2">{{ t("backend.columns.features") }}</th>
              <th class="p-2 text-right">{{ t("backend.columns.users") }}</th>
              <th class="p-2">{{ t("backend.columns.createdAt") }}</th>
              <th class="p-2 text-right">{{ t("backend.columns.actions") }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="account in accounts ?? []"
              :key="account.id"
              class="border-b border-rule odd:bg-surface-stripe"
              :data-test="`account-${account.id}`"
            >
              <td class="p-2">{{ account.name }}</td>
              <td class="p-2">{{ account.plan ?? "—" }}</td>
              <td class="p-2">{{ features(account) }}</td>
              <td class="p-2 text-right">{{ account.usersCount }}</td>
              <td class="p-2 whitespace-nowrap">{{ dates.format(new Date(account.createdAt)) }}</td>
              <td class="p-2 text-right">
                <RouterLink
                  v-slot="{ href, navigate }"
                  :to="{ name: 'backend-account-edit', params: { id: account.id } }"
                  custom
                >
                  <UiButton
                    as="a"
                    size="small"
                    :href="href"
                    :title="t('backend.edit')"
                    :data-test="`edit-${account.id}`"
                    @click="navigate"
                  >
                    <i class="fa fa-edit"></i>
                  </UiButton>
                </RouterLink>
              </td>
            </tr>

            <tr v-if="(accounts?.length ?? 0) === 0">
              <td class="p-2 text-muted" colspan="6" data-test="empty">
                {{ t("backend.accounts.empty") }}
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
      @go="router.push({ query: { ...route.query, page: String($event) } })"
    />
  </div>
</template>

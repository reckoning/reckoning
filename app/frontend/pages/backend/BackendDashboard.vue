<script setup lang="ts">
import { computed } from "vue"
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useBackendStats, useBackendUsers } from "@/services/api/services/backend/backend"
import UiButton from "@/components/ui/UiButton.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

// `backend/base/dashboard`: how much there is of everything, and the ten
// users who signed up last. The panel beside it printed
// `Rails.application.credentials` — including the SMTP password its own
// translation names — and is deliberately not ported.
const { t, locale } = useI18n()

const { data: stats } = useBackendStats()
const { data: users, isPending } = useBackendUsers({ perPage: 10 })

const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, { dateStyle: "medium", timeStyle: "short" }),
)

function moment(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(value)) : t("backend.never")
}
</script>

<template>
  <div id="backend-dashboard">
    <h1 data-test="backend-title">{{ t("backend.title") }}</h1>

    <div class="mt-4 grid grid-cols-12 gap-4">
      <div class="col-span-12 md:col-span-4">
        <UiPanel :title="t('backend.counts')" data-test="counts-panel">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <div class="text-muted">{{ t("backend.usersCount") }}</div>
              <div class="text-2xl" data-test="users-count">{{ stats?.usersCount ?? "—" }}</div>
            </div>
            <div>
              <div class="text-muted">{{ t("backend.accountsCount") }}</div>
              <div class="text-2xl" data-test="accounts-count">
                {{ stats?.accountsCount ?? "—" }}
              </div>
            </div>
          </div>

        </UiPanel>
      </div>

      <div class="col-span-12 md:col-span-8">
        <UiPanel :title="t('backend.latestUsers')" data-test="latest-users">
          <p v-if="isPending" class="text-muted">{{ t("backend.loading") }}</p>

          <div v-else class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b-2 border-rule-strong text-left">
                  <th class="p-2">{{ t("backend.columns.email") }}</th>
                  <th class="p-2">{{ t("backend.columns.createdAt") }}</th>
                  <th class="p-2">{{ t("backend.columns.currentSignInAt") }}</th>
                  <th class="p-2"></th>
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
                  <td class="p-2 whitespace-nowrap">{{ moment(user.createdAt) }}</td>
                  <td class="p-2 whitespace-nowrap">{{ moment(user.currentSignInAt) }}</td>
                  <td class="p-2 text-right">
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
                        @click="navigate"
                      >
                        <i class="fa fa-edit"></i>
                      </UiButton>
                    </RouterLink>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </UiPanel>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useCustomers } from "@/services/api/services/customers/customers"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

const { t } = useI18n()
const { data: customers, isPending, isError } = useCustomers()
</script>

<template>
  <div id="customers">
    <h1>{{ t("customers.title") }}</h1>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("customers.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("customers.loadFailed") }}</p>
    <p v-else-if="customers && customers.length === 0" class="mt-4" data-test="empty">
      {{ t("customers.empty") }}
    </p>

    <UiPanel v-else class="mt-4" list data-test="customers">
      <UiListGroup>
        <UiListGroupItem v-for="customer in customers" :key="customer.id" interactive>
          <RouterLink
            :to="{ name: 'customer-edit', params: { id: customer.id } }"
            class="text-ink hover:text-ink"
            :data-test="`customer-${customer.id}`"
          >
            <b>{{ customer.name }}</b>
          </RouterLink>
        </UiListGroupItem>
      </UiListGroup>
    </UiPanel>
  </div>
</template>

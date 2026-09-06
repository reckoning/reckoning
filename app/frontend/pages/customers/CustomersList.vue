<script setup lang="ts">
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useCustomers } from "@/services/api/services/customers/customers"

const { t } = useI18n()
const { data: customers, isPending, isError } = useCustomers()
</script>

<template>
  <div class="p-4">
    <h1 class="mb-4 text-[24px] font-medium">{{ t("customers.title") }}</h1>

    <p v-if="isPending" data-test="loading">{{ t("customers.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("customers.loadFailed") }}</p>
    <p v-else-if="customers && customers.length === 0" data-test="empty">{{ t("customers.empty") }}</p>

    <ul v-else class="divide-y divide-rule border-y border-rule" data-test="customers">
      <li v-for="customer in customers" :key="customer.id" class="py-2">
        <RouterLink
          :to="{ name: 'customer-edit', params: { id: customer.id } }"
          class="text-brand"
          :data-test="`customer-${customer.id}`"
        >
          {{ customer.name }}
        </RouterLink>
      </li>
    </ul>
  </div>
</template>

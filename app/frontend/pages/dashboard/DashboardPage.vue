<script setup lang="ts">
import { useI18n } from "vue-i18n"
import { useCurrentUserStore } from "@/stores/currentUser"

const { t } = useI18n()
const currentUser = useCurrentUserStore()
</script>

<template>
  <div class="p-4">
    <h1 class="text-xl font-semibold" data-testid="dashboard-title">
      {{ t("dashboard.title") }}
    </h1>

    <p v-if="currentUser.user" class="mt-2 text-gray-600" data-testid="dashboard-greeting">
      {{ t("dashboard.greeting", { email: currentUser.user.email }) }}
    </p>
  </div>
</template>

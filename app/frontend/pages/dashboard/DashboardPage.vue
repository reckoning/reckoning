<script setup lang="ts">
import { useI18n } from "vue-i18n"
import { useCurrentUserStore } from "@/stores/currentUser"

const { t } = useI18n()
const currentUser = useCurrentUserStore()
</script>

<template>
  <div id="dashboard">
    <h1 data-test="dashboard-title">
      {{ t("dashboard.title") }}
    </h1>

    <p v-if="currentUser.user" class="mt-4 text-muted" data-test="dashboard-greeting">
      {{ t("dashboard.greeting", { email: currentUser.user.email }) }}
    </p>
  </div>
</template>

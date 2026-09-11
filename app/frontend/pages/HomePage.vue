<script setup lang="ts">
import { computed, defineAsyncComponent } from "vue"
import { useCurrentUserStore } from "@/stores/currentUser"

// `/` is two screens, the way `BaseController#index` had it: the dashboard
// for whoever is signed in, and the welcome page for everyone else. A
// redirect between them would put a second URL on one of the two.
const currentUser = useCurrentUserStore()

const DashboardPage = defineAsyncComponent(() => import("@/pages/dashboard/DashboardPage.vue"))
const WelcomePage = defineAsyncComponent(() => import("@/pages/welcome/WelcomePage.vue"))

const page = computed(() => (currentUser.signedIn ? DashboardPage : WelcomePage))
</script>

<template>
  <component :is="page" />
</template>

<script setup lang="ts">
import { useRouter, RouterLink, RouterView } from "vue-router"
import { useI18n } from "vue-i18n"
import { useCurrentUserStore } from "@/stores/currentUser"
import ToastHost from "@/components/ToastHost.vue"

const { t } = useI18n()
const router = useRouter()
const currentUser = useCurrentUserStore()

async function signOut(): Promise<void> {
  await currentUser.signOut()
  await router.replace({ name: "login" })
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 text-gray-900">
    <header v-if="currentUser.signedIn" class="border-b border-gray-200 bg-white">
      <nav class="mx-auto flex max-w-6xl items-center gap-6 px-4 py-3">
        <RouterLink :to="{ name: 'dashboard' }" class="font-semibold">
          {{ t("nav.dashboard") }}
        </RouterLink>
        <RouterLink :to="{ name: 'customers' }">
          {{ t("nav.customers") }}
        </RouterLink>

        <span v-if="currentUser.user" class="ml-auto text-sm text-gray-500" data-testid="account">
          {{ currentUser.user.email }}
        </span>

        <button type="button" data-testid="sign-out" class="text-sm underline" @click="signOut">
          {{ t("nav.signOut") }}
        </button>
      </nav>
    </header>

    <main class="mx-auto max-w-6xl">
      <RouterView />
    </main>

    <ToastHost />
  </div>
</template>

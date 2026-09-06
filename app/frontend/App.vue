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
  <!-- White, like the server-rendered layout. `flow-root` stops the auth
       pages' top margin collapsing out and dragging the shell down with it. -->
  <div class="flow-root min-h-screen bg-surface text-ink">
    <header v-if="currentUser.signedIn" class="border-b border-rule bg-surface">
      <nav class="mx-auto flex max-w-6xl items-center gap-6 px-4 py-3">
        <RouterLink :to="{ name: 'dashboard' }" class="font-semibold">
          {{ t("nav.dashboard") }}
        </RouterLink>
        <RouterLink :to="{ name: 'customers' }">
          {{ t("nav.customers") }}
        </RouterLink>
        <RouterLink :to="{ name: 'two-factor' }" data-test="nav-two-factor">
          {{ t("nav.security") }}
        </RouterLink>

        <!-- Most of the product is still server-rendered, and signing in now
             lands here rather than there. Until phase C folds the two into one
             nav, this is the way across. -->
        <a href="/" class="text-sm" data-test="nav-legacy">
          {{ t("nav.legacy") }}
        </a>

        <span v-if="currentUser.user" class="ml-auto text-sm text-gray-500" data-test="account">
          {{ currentUser.user.email }}
        </span>

        <button type="button" data-test="sign-out" class="text-sm underline" @click="signOut">
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

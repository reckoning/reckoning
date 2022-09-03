<template>
  <!-- <NavigationMobile ref="mobileNavigation" /> -->

  <NavigationDesktop v-if="authenticated" />

  <div :class="mainClasses" class="flex flex-col flex-1 min-h-screen">
    <div
      v-if="authenticated"
      class="sticky top-0 z-10 md:hidden pl-1 pt-1 sm:pl-3 sm:pt-3 bg-gray-100"
    >
      <button
        type="button"
        class="-ml-0.5 -mt-0.5 h-12 w-12 inline-flex items-center justify-center rounded-md text-gray-500 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
        @click="openNavigation"
      >
        <span class="sr-only">Open sidebar</span>
        <!-- Heroicon name: outline/menu -->
        <svg
          class="h-6 w-6"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M4 6h16M4 12h16M4 18h16"
          />
        </svg>
      </button>
    </div>
    <main class="flex-1">
      <router-view :key="String(route.name)" v-slot="{ Component }">
        <transition name="fade" mode="out-in" :appear="true">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>
  </div>

  <AppFooter />
</template>

<script lang="ts" setup>
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useRoute } from 'vue-router'
import useAuthStore from '@/frontend/stores/Auth'
import NavigationMobile from '@/frontend/components/NavigationMobile.vue'
import NavigationDesktop from '@/frontend/components/NavigationDesktop.vue'
import AppFooter from '@/components/AppFooter.vue'

const route = useRoute()

const mobileNavigation = ref<InstanceType<typeof NavigationMobile> | null>(null)

function openNavigation() {
  if (mobileNavigation.value) {
    mobileNavigation.value.open()
  }
}

const authStore = useAuthStore()
const { authenticated } = storeToRefs(authStore)

const mainClasses = computed(() => {
  if (authStore.authenticated) {
    return 'md:pl-64'
  }

  return null
})
</script>

<style lang="scss">
.fade-enter-active,
.fade-leave-active {
  transition: opacity 1s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>

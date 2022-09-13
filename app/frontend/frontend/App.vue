<template>
  <Navigation v-if="authenticated" />

  <div :class="mainClasses" class="flex flex-col flex-1 min-h-screen">
    <SearchBar v-if="authenticated" />

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
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useRoute } from 'vue-router'
import useAuthStore from '@/frontend/stores/Auth'
import Navigation from '@/frontend/components/AppNavigation.vue'
import SearchBar from '@/frontend/components/SearchBar.vue'
import AppFooter from '@/components/AppFooter.vue'

const route = useRoute()

// Authentication State
const authStore = useAuthStore()
const { authenticated } = storeToRefs(authStore)

const mainClasses = computed(() => {
  if (authStore.authenticated) {
    return 'md:pl-64'
  }

  return null
})
</script>

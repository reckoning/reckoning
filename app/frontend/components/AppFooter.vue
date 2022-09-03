<template>
  <!-- This example requires Tailwind CSS v2.0+ -->
  <footer class="bg-white" :class="mainClasses">
    <div class="mx-auto max-w-7xl overflow-hidden py-12 px-4 sm:px-6 lg:px-8">
      <nav
        class="-mx-5 -my-2 flex flex-wrap justify-center"
        aria-label="Footer"
      >
        <div class="px-5 py-2">
          <router-link
            :to="{ name: 'impressum' }"
            class="text-base text-gray-500 hover:text-gray-900"
          >
            Impressum
          </router-link>
        </div>

        <div class="px-5 py-2">
          <router-link
            :to="{ name: 'privacy-policy' }"
            class="text-base text-gray-500 hover:text-gray-900"
          >
            Privacy Policy
          </router-link>
        </div>
      </nav>
      <div class="mt-8 flex justify-center space-x-6">
        <a href="#" class="text-gray-400 hover:text-gray-500">
          <span class="sr-only">Twitter</span>
          <i class="fa fa-twitter"></i>
        </a>
        <a href="#" class="text-gray-400 hover:text-gray-500">
          <span class="sr-only">GitHub</span>
          <i class="fa fa-github"></i>
        </a>
      </div>
      <p class="mt-8 text-center text-base text-gray-400">
        &copy; 2022 Marten Klitzke. All rights reserved.
      </p>
    </div>
  </footer>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import useAuthStore from '@/frontend/stores/Auth'

const authStore = useAuthStore()

const mainClasses = computed(() => {
  if (authStore.authenticated) {
    return 'md:pl-64'
  }

  return null
})
</script>

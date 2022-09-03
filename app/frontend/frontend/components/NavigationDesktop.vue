<template>
  <!-- Static sidebar for desktop -->
  <div class="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
    <!-- Sidebar component, swap this element with another sidebar if you like -->
    <div class="flex-1 flex flex-col min-h-0 border-r border-gray-200 bg-white">
      <div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
        <div class="flex items-center flex-shrink-0 px-4">
          <h1 class="text-lg">
            <router-link :to="{ name: 'home' }">Reckoning</router-link>
          </h1>
        </div>

        <nav class="mt-5 flex-1 px-2 bg-white space-y-1">
          <NavItem route-name="home" title="Dashboard" icon="fad fa-home-alt" />
          <NavItem
            route-name="invoices"
            title="Invoices"
            icon="fad fa-file-invoice"
          />
          <NavItem
            route-name="projects"
            title="Projects"
            icon="fad fa-square-kanban"
          />
          <NavItem route-name="timers" title="Timers" icon="fad fa-timer" />
          <NavItem route-name="expenses" title="Expenses" icon="fad fa-coins" />
        </nav>
      </div>
      <div v-if="user" class="flex-shrink-0 flex border-t border-gray-200 p-4">
        <a href="#" class="flex-shrink-0 w-full group block" @click="logout">
          <div class="flex items-center">
            <div>
              <img
                class="inline-block h-9 w-9 rounded-full"
                :src="user.avatar"
                alt="avatar"
              />
            </div>
            <div class="ml-3">
              <p
                class="text-sm font-medium text-gray-700 group-hover:text-gray-900"
              >
                {{ user.name }}
              </p>
              <p
                class="text-xs font-medium text-gray-500 group-hover:text-gray-700"
              >
                View profile
              </p>
            </div>
          </div>
        </a>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { User } from '@/frontend/api/client/models/User'
import NavItem from '@/components/navigation/NavItem.vue'
import apiClient from '@/frontend/api'
import useAuthStore from '@/frontend/stores/Auth'

const user = ref<User | null>(null)

onMounted(async () => {
  try {
    user.value = await apiClient.users.getMe()
  } catch (error) {
    // console.error(error)
  }
})

const authStore = useAuthStore()
const router = useRouter()

function logout() {
  authStore.logout()

  router.push({ name: 'home' })
}
</script>

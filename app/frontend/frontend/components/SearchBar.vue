<template>
  <div class="sticky top-0 z-10 flex h-16 flex-shrink-0 bg-white shadow">
    <button
      type="button"
      class="border-r border-gray-200 px-4 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500 md:hidden"
      @click="openNavigation"
    >
      <span class="sr-only">Open sidebar</span>
      <Bars3BottomLeftIcon class="h-6 w-6" aria-hidden="true" />
    </button>
    <div class="flex flex-1 justify-between px-4">
      <div class="flex flex-1">
        <form class="flex w-full md:ml-0" action="#" method="GET">
          <label for="search-field" class="sr-only">Search</label>
          <div class="relative w-full text-gray-400 focus-within:text-gray-600">
            <div
              class="pointer-events-none absolute inset-y-0 left-0 flex items-center"
            >
              <MagnifyingGlassIcon class="h-5 w-5" aria-hidden="true" />
            </div>
            <input
              id="search-field"
              class="block h-full w-full border-transparent py-2 pl-8 pr-3 text-gray-900 placeholder-gray-500 focus:border-transparent focus:placeholder-gray-400 focus:outline-none focus:ring-0 sm:text-sm"
              placeholder="Search"
              type="search"
              name="search"
            />
          </div>
        </form>
      </div>
      <div class="ml-4 flex items-center md:ml-6">
        <button
          type="button"
          class="rounded-full bg-white p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
        >
          <span class="sr-only">View notifications</span>
          <BellIcon class="h-6 w-6" aria-hidden="true" />
        </button>

        <!-- Profile dropdown -->
        <Menu as="div" class="relative ml-3">
          <div>
            <MenuButton
              class="flex max-w-xs items-center rounded-full bg-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              <span class="sr-only">Open user menu</span>
              <img
                v-if="user"
                class="h-8 w-8 rounded-full"
                :src="user.avatar"
                alt=""
              />
            </MenuButton>
          </div>
          <transition
            enter-active-class="transition ease-out duration-100"
            enter-from-class="transform opacity-0 scale-95"
            enter-to-class="transform opacity-100 scale-100"
            leave-active-class="transition ease-in duration-75"
            leave-from-class="transform opacity-100 scale-100"
            leave-to-class="transform opacity-0 scale-95"
          >
            <MenuItems
              class="absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
            >
              <MenuItem
                v-for="item in userNavigation"
                :key="item.name"
                v-slot="{ active }"
              >
                <a
                  :href="item.href"
                  :class="[
                    active ? 'bg-gray-100' : '',
                    'block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100',
                  ]"
                  >{{ item.name }}</a
                >
              </MenuItem>
              <MenuItem key="sign-out">
                <a
                  href="#"
                  class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                  @click="logout"
                >
                  Sign out
                </a>
              </MenuItem>
            </MenuItems>
          </transition>
        </Menu>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  Bars3BottomLeftIcon,
  MagnifyingGlassIcon,
  BellIcon,
} from '@heroicons/vue/24/outline'
import { Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import useAuthStore from '@/frontend/stores/Auth'
import useAppStore from '@/frontend/stores/App'
import type { User } from '@/frontend/api/client/models/User'
import apiClient from '@/frontend/api'

const userNavigation = [
  { name: 'Your Profile', href: '#' },
  { name: 'Settings', href: '#' },
]

// Navigation
const appStore = useAppStore()

function openNavigation() {
  if (appStore.navigationOpen) {
    appStore.closeNavigation()
  } else {
    appStore.openNavigation()
  }
}

// Fetch Current User
const user = ref<User | null>(null)

onMounted(async () => {
  try {
    user.value = await apiClient.users.getMe()
  } catch (error) {
    // console.error(error)
  }
})

// Authentication
const authStore = useAuthStore()
const router = useRouter()

const logout = () => {
  authStore.logout()

  router.push({ name: 'home' })
}
</script>

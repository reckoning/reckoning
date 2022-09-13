<template>
  <div class="h-0 flex-1 overflow-y-auto pt-5 pb-4">
    <div class="flex flex-shrink-0 items-center px-4">
      <p class="text-gray-200 text-2xl brand">Reckoning</p>
    </div>
    <nav class="mt-5 space-y-1 px-2">
      <router-link
        v-for="item in items"
        :key="item.name"
        :to="(item.to as RouteLocation)"
        :class="[
          isActive(String(item.to.name))
            ? 'bg-gray-900 text-white'
            : 'text-gray-300 hover:bg-gray-700 hover:text-white',
          'group flex items-center px-2 py-2 text-base font-medium rounded-md',
        ]"
      >
        <component
          :is="item.icon"
          :class="[
            isActive(String(item.to.name))
              ? 'text-gray-300'
              : 'text-gray-400 group-hover:text-gray-300',
            'mr-4 flex-shrink-0 h-6 w-6',
          ]"
          aria-hidden="true"
        />
        {{ item.name }}
      </router-link>
    </nav>
  </div>
</template>

<script lang="ts" setup>
// import { Component } from 'vue'
import { useRoute } from 'vue-router'
import type { RouteLocation } from 'vue-router'

export type NavigationItem = {
  name: string
  to: Partial<RouteLocation>
  icon: any
  current: boolean
}

export interface Props {
  items: NavigationItem[]
}

const { items } = withDefaults(defineProps<Props>(), {})

// Active Navigation
const route = useRoute()
const isActive = (routeName: string): boolean => {
  if (route.name === routeName) {
    return true
  }

  return false
}
</script>

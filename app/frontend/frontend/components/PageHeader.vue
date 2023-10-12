<template>
  <div>
    <div>
      <nav class="sm:hidden" aria-label="Back">
        <router-link
          to=":back"
          class="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
        >
          <ChevronLeftIcon
            class="-ml-1 mr-1 h-5 w-5 flex-shrink-0 text-gray-400"
            aria-hidden="true"
          />
          Back
        </router-link>
      </nav>
      <nav class="hidden sm:flex" aria-label="Breadcrumb">
        <ol role="list" class="flex items-center space-x-4">
          <li v-for="(breadcrumb, index) in breadcrumbs" :key="index">
            <div class="flex items-center">
              <ChevronRightIcon
                v-if="index > 0"
                class="h-5 w-5 flex-shrink-0 text-gray-400"
                aria-hidden="true"
              />
              <router-link
                :to="breadcrumb.to"
                class="text-sm font-medium text-gray-500 hover:text-gray-700"
                :class="{
                  'ml-4': index > 0,
                }"
              >
                {{ breadcrumb.name }}
              </router-link>
            </div>
          </li>
        </ol>
      </nav>
    </div>
    <div class="mt-2 md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h1 class="text-2xl text-gray-900 sm:truncate sm:text-3xl">
          {{ title }}
        </h1>
      </div>
      <div class="mt-4 flex flex-shrink-0 md:mt-0 md:ml-4">
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ChevronLeftIcon, ChevronRightIcon } from "@heroicons/vue/20/solid";
import type { RouteLocationRaw } from "vue-router";

export type Breadcrumb = {
  to: RouteLocationRaw;
  name: string;
};

export interface Props {
  title: string;
  breadcrumbs?: Breadcrumb[];
}

defineProps<Props>();
</script>

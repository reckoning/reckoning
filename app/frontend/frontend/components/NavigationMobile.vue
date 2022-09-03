<template>
  <!-- Off-canvas menu for mobile, show/hide based on off-canvas menu state. -->
  <div
    class="relative z-40 md:hidden"
    role="dialog"
    aria-modal="true"
    :style="{
      display: visible ? undefined : 'none',
    }"
  >
    <!--
      Off-canvas menu backdrop, show/hide based on off-canvas menu state.

      Entering: "transition-opacity ease-linear duration-300"
        From: "opacity-0"
        To: "opacity-100"
      Leaving: "transition-opacity ease-linear duration-300"
        From: "opacity-100"
        To: "opacity-0"
    -->
    <div
      class="fixed inset-0 bg-gray-600 bg-opacity-75"
      :class="{
        'opacity-100': visible,
        'opacity-0': !visible,
      }"
    ></div>

    <div class="fixed inset-0 flex z-40">
      <!--
        Off-canvas menu, show/hide based on off-canvas menu state.

        Entering: "transition ease-in-out duration-300 transform"
          From: "-translate-x-full"
          To: "translate-x-0"
        Leaving: "transition ease-in-out duration-300 transform"
          From: "translate-x-0"
          To: "-translate-x-full"
      -->
      <div
        class="relative flex-1 flex flex-col max-w-xs w-full bg-white"
        :class="{
          'translate-x-0': visible,
          '-translate-x-full': !visible,
        }"
      >
        <!--
          Close button, show/hide based on off-canvas menu state.

          Entering: "ease-in-out duration-300"
            From: "opacity-0"
            To: "opacity-100"
          Leaving: "ease-in-out duration-300"
            From: "opacity-100"
            To: "opacity-0"
        -->
        <div
          class="absolute top-0 right-0 -mr-12 pt-2"
          :class="{
            'opacity-100': visible,
            'opacity-0': !visible,
          }"
        >
          <button
            type="button"
            class="ml-1 flex items-center justify-center h-10 w-10 rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
            @click="close"
          >
            <span class="sr-only">Close sidebar</span>
            <!-- Heroicon name: outline/x -->
            <svg
              class="h-6 w-6 text-white"
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
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div class="flex-1 h-0 pt-5 pb-4 overflow-y-auto">
          <div class="flex-shrink-0 flex items-center px-4">
            <h1>Reckoning</h1>
          </div>
          <nav class="mt-5 px-2 space-y-1">
            <!-- Current: "bg-gray-100 text-gray-900", Default: "text-gray-600 hover:bg-gray-50 hover:text-gray-900" -->
            <a
              href="#"
              class="bg-gray-100 text-gray-900 group flex items-center px-2 py-2 text-base font-medium rounded-md"
            >
              <!--
                Heroicon name: outline/home

                Current: "text-gray-500", Default: "text-gray-400 group-hover:text-gray-500"
              -->
              <svg
                class="text-gray-500 mr-4 flex-shrink-0 h-6 w-6"
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
                  d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                />
              </svg>
              Dashboard
            </a>

            <a
              href="#"
              class="text-gray-600 hover:bg-gray-50 hover:text-gray-900 group flex items-center px-2 py-2 text-base font-medium rounded-md"
            >
              <!-- Heroicon name: outline/users -->
              <svg
                class="text-gray-400 group-hover:text-gray-500 mr-4 flex-shrink-0 h-6 w-6"
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
                  d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                />
              </svg>
              Team
            </a>

            <a
              href="#"
              class="text-gray-600 hover:bg-gray-50 hover:text-gray-900 group flex items-center px-2 py-2 text-base font-medium rounded-md"
            >
              <!-- Heroicon name: outline/folder -->
              <svg
                class="text-gray-400 group-hover:text-gray-500 mr-4 flex-shrink-0 h-6 w-6"
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
                  d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                />
              </svg>
              Projects
            </a>

            <a
              href="#"
              class="text-gray-600 hover:bg-gray-50 hover:text-gray-900 group flex items-center px-2 py-2 text-base font-medium rounded-md"
            >
              <!-- Heroicon name: outline/calendar -->
              <svg
                class="text-gray-400 group-hover:text-gray-500 mr-4 flex-shrink-0 h-6 w-6"
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
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              Calendar
            </a>

            <a
              href="#"
              class="text-gray-600 hover:bg-gray-50 hover:text-gray-900 group flex items-center px-2 py-2 text-base font-medium rounded-md"
            >
              <!-- Heroicon name: outline/inbox -->
              <svg
                class="text-gray-400 group-hover:text-gray-500 mr-4 flex-shrink-0 h-6 w-6"
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
                  d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                />
              </svg>
              Documents
            </a>

            <a
              href="#"
              class="text-gray-600 hover:bg-gray-50 hover:text-gray-900 group flex items-center px-2 py-2 text-base font-medium rounded-md"
            >
              <!-- Heroicon name: outline/chart-bar -->
              <svg
                class="text-gray-400 group-hover:text-gray-500 mr-4 flex-shrink-0 h-6 w-6"
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
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              Reports
            </a>
          </nav>
        </div>
        <div class="flex-shrink-0 flex border-t border-gray-200 p-4">
          <a href="#" class="flex-shrink-0 group block">
            <div class="flex items-center">
              <div>
                <img
                  class="inline-block h-10 w-10 rounded-full"
                  src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
              </div>
              <div class="ml-3">
                <p
                  class="text-base font-medium text-gray-700 group-hover:text-gray-900"
                >
                  Tom Cook
                </p>
                <p
                  class="text-sm font-medium text-gray-500 group-hover:text-gray-700"
                >
                  View profile
                </p>
              </div>
            </div>
          </a>
        </div>
      </div>

      <div class="flex-shrink-0 w-14"></div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref } from 'vue'

const visible = ref<boolean>(false)

function open() {
  visible.value = true
}

function close() {
  visible.value = false
}

defineExpose({
  open,
  close,
})
</script>

<style></style>

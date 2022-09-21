<template>
  <TransitionRoot as="template" :show="navigationOpen">
    <Dialog as="div" class="relative z-40 md:hidden" @close="closeNavigation">
      <TransitionChild
        as="template"
        enter="transition-opacity ease-linear duration-300"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="transition-opacity ease-linear duration-300"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-gray-600 bg-opacity-75" />
      </TransitionChild>

      <div class="fixed inset-0 z-40 flex">
        <TransitionChild
          as="template"
          enter="transition ease-in-out duration-300 transform"
          enter-from="-translate-x-full"
          enter-to="translate-x-0"
          leave="transition ease-in-out duration-300 transform"
          leave-from="translate-x-0"
          leave-to="-translate-x-full"
        >
          <DialogPanel
            class="relative flex w-full max-w-xs flex-1 flex-col bg-gray-800"
          >
            <TransitionChild
              as="template"
              enter="ease-in-out duration-300"
              enter-from="opacity-0"
              enter-to="opacity-100"
              leave="ease-in-out duration-300"
              leave-from="opacity-100"
              leave-to="opacity-0"
            >
              <div class="absolute top-0 right-0 -mr-12 pt-2">
                <button
                  type="button"
                  class="ml-1 flex h-10 w-10 items-center justify-center rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                  @click="closeNavigation"
                >
                  <span class="sr-only">Close sidebar</span>
                  <XMarkIcon class="h-6 w-6 text-white" aria-hidden="true" />
                </button>
              </div>
            </TransitionChild>
            <MainNavigation :items="navigationItems" />
          </DialogPanel>
        </TransitionChild>
        <div class="w-14 flex-shrink-0">
          <!-- Force sidebar to shrink to fit close icon -->
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
  <!-- Static sidebar for desktop -->
  <div class="hidden md:fixed md:inset-y-0 md:flex md:w-64 md:flex-col">
    <!-- Sidebar component, swap this element with another sidebar if you like -->
    <div class="flex min-h-0 flex-1 flex-col bg-gray-800">
      <MainNavigation :items="navigationItems" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import {
  Dialog,
  DialogPanel,
  TransitionChild,
  TransitionRoot,
} from "@headlessui/vue";
import {
  ClockIcon,
  RectangleStackIcon,
  HomeIcon,
  DocumentTextIcon,
  WalletIcon,
  XMarkIcon,
  CalculatorIcon,
} from "@heroicons/vue/24/outline";
import MainNavigation from "@/components/navigation/MainItems.vue";
import type { NavigationItem } from "@/components/navigation/MainItems.vue";
import useAppStore from "@/frontend/stores/App";

// Navigation Items
const navigationItems: NavigationItem[] = [
  {
    name: "Dashboard",
    to: { name: "dashboard" },
    icon: HomeIcon,
  },
  {
    name: "Invoices",
    to: { name: "invoices" },
    icon: DocumentTextIcon,
  },
  {
    name: "Projects",
    to: { name: "projects" },
    icon: RectangleStackIcon,
  },
  { name: "Timers", to: { name: "timers" }, icon: ClockIcon },
  {
    name: "Expenses",
    to: { name: "expenses" },
    icon: WalletIcon,
  },
  {
    name: "Calculator",
    to: { name: "calculator" },
    icon: CalculatorIcon,
    activeRoutes: ["calculator", "calculator-item"],
  },
];

const appStore = useAppStore();

const { navigationOpen } = storeToRefs(appStore);

const closeNavigation = () => {
  appStore.closeNavigation();
};
</script>

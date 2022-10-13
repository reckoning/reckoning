<template>
  <div
    :class="[
      'bg-purple-600',
      'flex-shrink-0 flex items-center text-uppercase justify-center w-24 text-white text-lg font-medium rounded-l-md',
    ]"
  >
    {{ timer.projectName?.slice(0, 2) }}
  </div>
  <div
    class="flex flex-1 items-center justify-between truncate rounded-r-md border-t border-r border-b border-gray-200 bg-white"
  >
    <div class="flex-1 truncate px-6 py-4 text-sm">
      <a
        :href="timer.projectId"
        class="font-medium text-lg font-hero text-gray-900 hover:text-gray-600"
        >{{ timer.projectName }}</a
      >
      <p class="text-gray-500">{{ timer.date }}</p>
      <p class="text-gray-500">{{ timer.createdAt }}</p>
    </div>
    <div class="flex-shrink-0 pr-2">
      <Btn size="md">Start</Btn>
      <Btn size="sm" color="secondary">Start</Btn>
      foo
      <button
        type="button"
        class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-white bg-transparent text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2"
      >
        <span class="sr-only">Open options</span>
        <EllipsisVerticalIcon class="h-5 w-5" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from "vue";
import { format } from "date-fns";
import type { Timer } from "@/frontend/api/client/models/Timer";
import { EllipsisVerticalIcon } from "@heroicons/vue/24/outline";
import Btn from "@/frontend/components/BtnComponent.vue";

export interface Props {
  timer: Timer;
}

const props = defineProps<Props>();
const difference = ref<number>(0);

onMounted(async () => {
  setInterval(() => {
    if (props.timer.startedAt) {
      difference.value = Math.round(
        (new Date().getTime() - new Date(props.timer.startedAt).getTime()) /
          1000
      );
    }
  }, 1000);
});
</script>

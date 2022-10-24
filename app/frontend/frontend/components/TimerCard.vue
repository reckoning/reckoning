<template>
  <div
    :class="[
      'bg-brand-primary',
      'flex-shrink-0 flex items-center uppercase justify-center w-24 text-white text-lg font-medium rounded-l-md',
    ]"
  >
    {{ timer.project.name?.slice(0, 2) }}
  </div>
  <div
    class="flex flex-1 items-center justify-between rounded-r-md border-t border-r border-b border-gray-200 bg-white"
  >
    <div class="flex-1 truncate px-6 py-4 text-sm">
      <router-link
        :to="{ name: 'project-detail', params: { id: timer.project.id } }"
        class="font-medium text-lg font-hero text-gray-900 hover:text-gray-600"
      >
        {{ timer.project.name }}
        <small>| {{ timer.project.customerName }}</small>
      </router-link>
      <p class="text-gray-500">
        {{ timer.task.label }}
        <template v-if="timer.note"> | {{ timer.note }}</template>
      </p>
    </div>
    <div
      class="flex-shrink-0 flex items-center text-2xl pr-5"
      :class="{ 'text-brand-primary': timer.startedAt }"
    >
      {{ timeValue }}
    </div>
    <div class="flex-shrink-0 flex items-center pr-2">
      <Btn
        :color="timer.startedAt ? 'success' : 'secondary'"
        class="mr-2"
        @click="toggle"
      >
        <i
          class="fa fa-circle-o-notch mr-2"
          :class="{ 'fa-spin': timer.startedAt }"
        ></i>
        <template v-if="timer.startedAt">Stop</template>
        <template v-else>Start</template>
      </Btn>

      <DropdownMenu />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted } from "vue";
import { format, differenceInSeconds } from "date-fns";
import type { Timer } from "@/frontend/api/client/models/Timer";
import Btn from "@/frontend/components/BtnComponent.vue";
import apiClient from "@/frontend/api";
import DropdownMenu from "@/frontend/components/DropdownMenu.vue";

export interface Props {
  timer: Timer;
}

const props = defineProps<Props>();
const currentTime = ref<Date>(new Date());

const timeValue = computed(() => {
  let seconds = props.timer.value * 60 * 60;

  if (props.timer.startedAt) {
    seconds += differenceInSeconds(
      currentTime.value,
      new Date(props.timer.startedAt)
    );
  }

  const time = new Date(0, 0, 0, 0, 0, Math.max(seconds, 0));

  return format(time, "H:mm");
});

onMounted(async () => {
  setInterval(() => {
    if (props.timer.startedAt) {
      currentTime.value = new Date();
    }
  }, 1000);
});

const toggle = async () => {
  try {
    if (props.timer.startedAt) {
      await apiClient.timers.stopTimer({ id: props.timer.id });
    } else {
      await apiClient.timers.startTimer({ id: props.timer.id });
    }
  } catch (error) {
    console.error(error);
  }
};
</script>

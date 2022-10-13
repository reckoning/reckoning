<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8">
      <h1 class="text-2xl text-gray-900">Timers</h1>
    </div>
    <div class="mx-auto mt-3 px-4 sm:px-6 md:px-8 flex space-x-5">
      <ul role="list" class="grid grid-cols-1 gap-5 sm:gap-6 flex-auto">
        <li
          v-for="timer in timers"
          :key="timer.id"
          class="col-span-1 flex rounded-md shadow-sm"
        >
          <TimerCard :timer="timer" />
        </li>
      </ul>
      <div class="flex-none">
        <Btn @click="createTimer">New Timer</Btn>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from "vue";
import type { Timer as TimerType } from "@/frontend/api/client/models/Timer";
import apiClient from "@/frontend/api";
import TimerCard from "@/frontend/components/TimerCard.vue";
import Btn from "@/frontend/components/BtnComponent.vue";
import { format } from "date-fns";

// Fetch Timers
const timers = ref<TimerType[] | []>([]);
const currentDate: string = format(new Date(), "yyyy-MM-dd");

const createTimer = async () => {
  await apiClient.timers.createTimer({
    requestBody: {
      date: currentDate,
      value: "0",
      taskId: "15ebae89-b1e6-4947-b70a-23d2cf9f799e",
      projectId: "dcf90db8-5fdd-4d4c-b517-966e95e6eb4a",
    },
  });

  fetchTimers();
};

const fetchTimers = async () => {
  try {
    timers.value = await apiClient.timers.getTimers({
      date: currentDate,
    });
  } catch (error) {
    // console.error(error)
  }
};

onMounted(() => {
  fetchTimers();
});
</script>

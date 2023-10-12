<template>
  <div class="py-6">
    <div class="px-4 sm:px-6 md:px-8 flex justify-between">
      <h1 class="text-2xl text-gray-900">
        {{ format(currentDate, "eeee - d. MMMM yyyy") }}
      </h1>
      <div class="flex">
        <Btn
          size="sm"
          variant="secondary"
          :to="{
            name: 'timers',
            query: { date: format(previousDay, 'yyyy-MM-dd') },
          }"
          grouped="right"
        >
          <span class="sr-only">Previous day</span>
          <i class="fa fa-chevron-left"></i>
        </Btn>

        <Btn
          size="sm"
          variant="secondary"
          :to="{ name: 'timers' }"
          grouped="both"
        >
          Today
        </Btn>
        <span class="relative -mx-px h-5 w-px bg-gray-300 md:hidden" />
        <Btn
          size="sm"
          variant="secondary"
          :to="{
            name: 'timers',
            query: { date: format(nextDay, 'yyyy-MM-dd') },
          }"
          grouped="left"
        >
          <span class="sr-only">Next day</span>
          <i class="fa fa-chevron-right"></i>
        </Btn>
      </div>
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
        <li
          v-if="!timers.length"
          key="no-timers"
          class="col-span-1 flex rounded-md shadow-sm"
        >
          <div
            class="flex flex-1 items-center justify-center rounded-md border border-gray-200 bg-gray-100 truncate px-6 py-4 text-sm"
          >
            No Timers found
          </div>
        </li>
      </ul>
      <div class="flex-none">
        <Btn size="lg" @click="createTimer">
          <i class="fa fa-plus mr-2" />
          New Timer
        </Btn>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted, watch, inject } from "vue";
import { useRoute } from "vue-router";
import { format, addDays } from "date-fns";
import type { Timer as TimerType } from "@/frontend/api/client/models/Timer";
import apiClient from "@/frontend/api";
import TimerCard from "@/frontend/components/TimerCard.vue";
import Btn from "@/frontend/components/BtnComponent.vue";
import TimersChannel from "@/frontend/channels/TimersChannel";
import type { Cable } from "@anycable/core";

const route = useRoute();

const currentDate = computed((): Date => {
  if (route.query.date) {
    return new Date(route.query.date as string);
  }

  return new Date();
});

const nextDay = computed(() => addDays(currentDate.value, 1));
const previousDay = computed(() => addDays(currentDate.value, -1));

// Fetch Timers
const timers = ref<TimerType[] | []>([]);

const createTimer = async () => {
  try {
    await apiClient.timers.createTimer({
      requestBody: {
        date: format(currentDate.value, "yyyy-MM-dd"),
        value: "0",
        taskId: "15ebae89-b1e6-4947-b70a-23d2cf9f799e",
        projectId: "dcf90db8-5fdd-4d4c-b517-966e95e6eb4a",
      },
    });
  } catch (error) {
    console.error(error);
  }

  fetchTimers();
};

const fetchTimers = async () => {
  try {
    timers.value = await apiClient.timers.getTimers({
      date: format(currentDate.value, "yyyy-MM-dd"),
    });
  } catch (error) {
    console.error(error);
  }
};

const $cable = inject<Cable>("$cable");

onMounted(() => {
  fetchTimers();

  setupSubscriptions();
});

watch(route, () => {
  fetchTimers();
});

function setupSubscriptions() {
  if (!$cable) {
    return;
  }

  const subscription = $cable.subscribe(new TimersChannel({ room: "all" }));

  subscription.on("message", () => {
    fetchTimers();
  });
}
</script>

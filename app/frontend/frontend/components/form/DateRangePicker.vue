<template>
  <div class="flex rounded-md shadow-sm">
    <input
      v-model="internalStartDate"
      type="date"
      name="startDate"
      :max="end"
      class="block w-full min-w-0 flex-1 rounded-none rounded-l-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
      @change="emitChange"
    />
    <span
      class="inline-flex items-center border border-l-0 border-r-0 border-gray-300 bg-gray-50 px-3 text-gray-500 sm:text-sm"
    >
      to
    </span>
    <input
      v-model="internalEndDate"
      type="date"
      name="endDate"
      :min="start"
      class="block w-full min-w-0 flex-1 rounded-none rounded-r-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
      @change="emitChange"
    />
  </div>
</template>

<script lang="ts" setup>
import { ref } from "vue";
const emit = defineEmits(["input"]);

const props = defineProps<{
  start?: string;
  end?: string;
}>();

const internalStartDate = ref(props.start);
const internalEndDate = ref(props.end);

const emitChange = (): void => {
  emit("input", internalStartDate, internalEndDate);
};
</script>

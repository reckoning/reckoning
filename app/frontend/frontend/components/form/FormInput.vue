<template>
  <div>
    <label
      v-if="label"
      :for="id"
      class="block text-sm font-medium text-gray-700"
    >
      {{ label }}
    </label>
    <div class="mt-1">
      <input
        :id="id"
        v-model="value"
        :type="type"
        :name="id"
        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue";

const emit = defineEmits(["update:modelValue"]);

const props = defineProps<{
  modelValue: string | number | null;
  type: "number" | "text";
  label?: string;
  id: string;
}>();

const value = computed({
  get() {
    return props.modelValue;
  },
  set(modelValue) {
    emit("update:modelValue", modelValue);
  },
});
</script>

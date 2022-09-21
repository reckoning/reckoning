<template>
  <div>
    <label
      :for="id"
      v-if="label"
      class="block text-sm font-medium text-gray-700"
    >
      {{ label }}
    </label>
    <div class="mt-1">
      <input
        :type="type"
        :name="id"
        :id="id"
        v-model="value"
        class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'

const emit = defineEmits(['update:modelValue'])

const props = defineProps<{
  modelValue: string | number | null
  type: 'number' | 'text'
  label?: string
  id: string
}>()

const value = computed({
  get() {
    return props.modelValue
  },
  set(value) {
    emit('update:modelValue', value)
  },
})
</script>

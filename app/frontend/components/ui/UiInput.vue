<script setup lang="ts">
// `.form-control`: 34px tall, its own inset shadow, and the blue glow on
// focus. One component so the shape lives in a single place — the forms
// carried the same class list five times over.
withDefaults(defineProps<{as?: "input" | "textarea" | "select"; modelValue?: string | number | null}>(), {
  as: "input",
  modelValue: "",
})

defineEmits<{"update:modelValue": [string]}>()

const CLASSES =
  "bs-input"
</script>

<template>
  <textarea
    v-if="as === 'textarea'"
    :class="CLASSES"
    :value="String(modelValue ?? '')"
    @input="$emit('update:modelValue', ($event.target as HTMLTextAreaElement).value)"
  ></textarea>

  <select
    v-else-if="as === 'select'"
    :class="[CLASSES, 'h-[34px]']"
    :value="modelValue"
    @change="$emit('update:modelValue', ($event.target as HTMLSelectElement).value)"
  >
    <slot />
  </select>

  <input
    v-else
    :class="[CLASSES, 'h-[34px]']"
    :value="modelValue"
    @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
  />
</template>

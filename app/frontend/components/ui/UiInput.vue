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
  "block w-full rounded-bs border border-field-border bg-surface px-3 py-1.5 text-base leading-[1.428571429] text-field shadow-[inset_0_1px_1px_rgba(0,0,0,0.075)] placeholder:text-placeholder focus:border-field-focus focus:shadow-[inset_0_1px_1px_rgba(0,0,0,0.075),0_0_8px_rgba(102,175,233,0.6)] focus:outline-none disabled:bg-surface-muted"
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

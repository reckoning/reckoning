<script setup lang="ts">
// `.form-group`: one label above one control, 15px apart from the next.
withDefaults(defineProps<{label?: string}>(), {label: undefined})
</script>

<template>
  <div class="mb-4">
    <label class="block">
      <span v-if="label" class="mb-1 inline-block font-bold">{{ label }}</span>
      <slot />
    </label>
    <slot name="error" />
  </div>
</template>

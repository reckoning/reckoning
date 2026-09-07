<script setup lang="ts">
// `.input-group`: an addon and a control welded into one outline. The addon
// is what the forms used instead of a label above the field.
withDefaults(defineProps<{addon?: string}>(), {addon: undefined})
</script>

<template>
  <div class="flex">
    <span
      v-if="addon || $slots.addon"
      class="flex items-center rounded-l-bs border border-r-0 border-field-border bg-addon px-3 text-base whitespace-nowrap text-field"
    >
      <slot name="addon">{{ addon }}</slot>
    </span>

    <div class="grow [&>*]:rounded-l-none">
      <slot />
    </div>

    <div v-if="$slots.button" class="[&>*]:rounded-l-none [&>*]:-ml-px">
      <slot name="button" />
    </div>
  </div>
</template>

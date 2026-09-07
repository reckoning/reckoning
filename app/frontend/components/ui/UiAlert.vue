<script setup lang="ts">
import { computed } from "vue"

// `.alert`, in the four flavours the flashes and the trial banner use.
const props = withDefaults(
  defineProps<{variant?: "info" | "success" | "warning" | "danger"}>(),
  {variant: "info"},
)

const VARIANTS = {
  info: "border-alert-info-border bg-alert-info text-alert-info-text",
  success: "border-alert-success-border bg-alert-success text-alert-success-text",
  warning: "border-alert-warning-border bg-alert-warning text-alert-warning-text",
  danger: "border-alert-danger-border bg-alert-danger text-alert-danger-text",
} as const

const classes = computed(() => ["mb-5 rounded-bs border px-4 py-3.5", VARIANTS[props.variant]])
</script>

<template>
  <div :class="classes">
    <slot />
  </div>
</template>

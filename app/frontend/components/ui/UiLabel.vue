<script setup lang="ts">
import { computed } from "vue"

// `.label`, which is how every state is printed in the server-rendered lists.
const props = withDefaults(
  defineProps<{variant?: "default" | "primary" | "success" | "info" | "warning" | "danger"}>(),
  {variant: "default"},
)

const FILLS = {
  default: "bg-muted",
  primary: "bg-brand",
  success: "bg-success",
  info: "bg-info",
  warning: "bg-warning",
  danger: "bg-danger",
} as const

// The geometry lives in `.bs-label`: it is `display: inline` on the
// baseline, and its size depends on whether it sits in a list row, which a
// utility class cannot express.
const classes = computed(() => ["bs-label", FILLS[props.variant]])
</script>

<template>
  <span :class="classes">
    <slot />
  </span>
</template>

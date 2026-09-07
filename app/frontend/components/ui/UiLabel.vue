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

// `.label` is 75% of the body size, which `application.scss` lifts to 90%
// inside a list row — the size the states are actually seen at.
const classes = computed(() => [
  "inline-block rounded-[0.25em] px-[0.6em] pt-[0.2em] pb-[0.3em] text-[90%] leading-none font-bold text-white",
  FILLS[props.variant],
])
</script>

<template>
  <span :class="classes">
    <slot />
  </span>
</template>

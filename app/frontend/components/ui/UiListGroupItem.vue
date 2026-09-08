<script setup lang="ts">
import { computed } from "vue"

// `.list-group-item`. Rendered as a link it takes the hover fill Bootstrap
// gives `a.list-group-item`; `variant` is the contextual fill the overtime
// panel uses to say how far off the hours are.
const props = withDefaults(
  defineProps<{
    interactive?: boolean
    variant?: "default" | "success" | "warning" | "danger"
    muted?: boolean
  }>(),
  {interactive: false, variant: "default", muted: false},
)

const VARIANTS = {
  default: "",
  success: "bg-alert-success text-alert-success-text",
  warning: "bg-alert-warning text-alert-warning-text",
  danger: "bg-alert-danger text-alert-danger-text",
} as const

const classes = computed(() => [
  "bs-list-item",
  VARIANTS[props.variant],
  // `.list-group-item.disabled`: a row that is there for reference, not for
  // acting on — the dashboard greys out last year's numbers that way.
  props.muted ? "bg-surface-muted text-muted" : "",
  props.interactive ? "hover:bg-surface-muted" : "",
])
</script>

<template>
  <div :class="classes">
    <slot />
  </div>
</template>

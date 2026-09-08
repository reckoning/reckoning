<script setup lang="ts">
import { computed } from "vue"

// Bootstrap 3's `.panel`: the box every server-rendered screen is built out
// of. `list` switches the heading to the tighter padding
// `partials/_panel-list.scss` gives a column-header row, and `variant` is the
// contextual colouring the dashboard puts on its invoice panels.
const props = withDefaults(
  defineProps<{
    title?: string
    list?: boolean
    variant?: "default" | "info" | "success" | "warning" | "danger"
  }>(),
  {title: undefined, list: false, variant: "default"},
)

const BORDERS = {
  default: "border-rule-strong",
  info: "border-alert-info-border",
  success: "border-alert-success-border",
  warning: "border-alert-warning-border",
  danger: "border-alert-danger-border",
} as const

const HEADINGS = {
  default: "border-rule-strong bg-surface-muted text-muted-strong",
  info: "border-alert-info-border bg-alert-info text-alert-info-text",
  success: "border-alert-success-border bg-alert-success text-alert-success-text",
  warning: "border-alert-warning-border bg-alert-warning text-alert-warning-text",
  danger: "border-alert-danger-border bg-alert-danger text-alert-danger-text",
} as const

const border = computed(() => BORDERS[props.variant])
const heading = computed(() => HEADINGS[props.variant])
</script>

<template>
  <div class="mb-5 rounded-bs border bg-surface" :class="border">
    <div
      v-if="title || $slots.heading"
      class="rounded-t-bs border-b"
      :class="[heading, list ? 'px-4 py-2' : 'px-4 py-2.5']"
    >
      <slot name="heading">
        <strong class="text-[length:var(--text-h3)]">{{ title }}</strong>
      </slot>
    </div>

    <div v-if="$slots.body" class="p-4">
      <slot name="body" />
    </div>

    <slot />
  </div>
</template>

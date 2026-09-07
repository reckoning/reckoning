<script setup lang="ts">
import { computed } from "vue"

// `.btn` with the three variants the screens use, plus `link` for the inline
// text buttons in the action lists.
const props = withDefaults(
  defineProps<{variant?: "default" | "primary" | "danger" | "link"; block?: boolean}>(),
  {variant: "default", block: false},
)

const VARIANTS = {
  default: "border-field-border bg-surface text-ink hover:border-control-hover-border hover:bg-control-hover",
  primary: "border-brand-border bg-brand text-white hover:border-brand-hover-border hover:bg-brand-hover",
  danger: "border-danger-border bg-danger text-white hover:border-danger-hover-border hover:bg-danger-hover",
  link: "border-transparent bg-transparent text-brand hover:underline",
} as const

const classes = computed(() => [
  "inline-block rounded-bs border px-3 py-1.5 text-center align-middle text-base leading-[1.428571429] whitespace-nowrap select-none disabled:opacity-65",
  VARIANTS[props.variant],
  props.block ? "block w-full" : "",
])
</script>

<template>
  <button :class="classes">
    <slot />
  </button>
</template>

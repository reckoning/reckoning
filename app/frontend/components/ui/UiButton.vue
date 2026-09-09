<script setup lang="ts">
import { computed } from "vue"

// `.btn` with the three variants the screens use, plus `link` for the inline
// text buttons in the action lists.
// `as: "a"` for a button that navigates — the whole element is the link, so
// nothing is nested inside anything. `as: "span"` is for the case where a
// link is already wrapped around it: a `<button>` inside an `<a>` is a second
// control inside the first, which leaves focus and activation unclear for the
// keyboard and for a screen reader.
const props = withDefaults(
  defineProps<{
    variant?: "default" | "primary" | "success" | "warning" | "danger" | "link"
    size?: "default" | "large" | "small"
    as?: "button" | "span" | "a"
    block?: boolean
  }>(),
  {variant: "default", size: "default", as: "button", block: false},
)

const VARIANTS = {
  default: "border-field-border bg-surface text-ink hover:border-control-hover-border hover:bg-control-hover",
  primary: "border-brand-border bg-brand text-white hover:border-brand-hover-border hover:bg-brand-hover",
  success:
    "border-success-border bg-success text-white hover:border-success-hover-border hover:bg-success-hover",
  warning:
    "border-warning-border bg-warning text-white hover:border-warning-hover-border hover:bg-warning-hover",
  danger: "border-danger-border bg-danger text-white hover:border-danger-hover-border hover:bg-danger-hover",
  link: "border-transparent bg-transparent text-brand hover:underline",
} as const

const SIZES = {
  default: "rounded-bs px-3 py-1.5 text-base",
  large: "rounded-bs-lg px-4 py-2.5 text-lg",
  small: "rounded-bs-sm px-2.5 py-1 text-small",
} as const

const classes = computed(() => [
  "inline-block border text-center align-middle leading-[1.428571429] whitespace-nowrap select-none disabled:opacity-65",
  SIZES[props.size],
  VARIANTS[props.variant],
  props.block ? "block w-full" : "",
])
</script>

<template>
  <component :is="as" :class="[classes, as === 'span' ? 'cursor-pointer' : '']">
    <slot />
  </component>
</template>

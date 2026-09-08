<script setup lang="ts">
import { computed } from "vue"
import { RouterLink } from "vue-router"
import type { RouteLocationRaw } from "vue-router"

// `.list-group-item`. Bootstrap had three of them — a plain `div`, an `a` and
// a `button` — and the last two are the whole row: what lights up on hover is
// what can be clicked. `variant` is the contextual fill the overtime panel
// uses to say how far off the hours are.
const props = withDefaults(
  defineProps<{
    interactive?: boolean
    variant?: "default" | "success" | "warning" | "danger"
    muted?: boolean
    to?: RouteLocationRaw
    href?: string
    target?: string
    action?: boolean
    disabled?: boolean
  }>(),
  {
    interactive: false,
    variant: "default",
    muted: false,
    to: undefined,
    href: undefined,
    target: undefined,
    action: false,
    disabled: false,
  },
)

const VARIANTS = {
  default: "",
  success: "bg-alert-success text-alert-success-text",
  warning: "bg-alert-warning text-alert-warning-text",
  danger: "bg-alert-danger text-alert-danger-text",
} as const

const element = computed(() => {
  if (props.to) return RouterLink
  if (props.href) return "a"
  if (props.action) return "button"

  return "div"
})

const control = computed(() => element.value !== "div")

// Only the attributes the chosen element actually takes: passing an
// undefined `href` alongside `to` reaches RouterLink as a fallthrough
// attribute and erases the href it renders itself, which costs the row its
// pointer and its middle-click.
const bindings = computed(() => {
  if (props.to) return {to: props.to}
  if (props.href) return {href: props.href, target: props.target}
  if (props.action) return {type: "button", disabled: props.disabled}

  return {}
})

const classes = computed(() => [
  "bs-list-item",
  VARIANTS[props.variant],
  // `.list-group-item.disabled`: a row that is there for reference, not for
  // acting on — the dashboard greys out last year's numbers that way.
  props.muted ? "bg-surface-muted text-muted" : "",
  props.interactive || control.value ? "hover:bg-surface-muted" : "",
  // `a.list-group-item` and `button.list-group-item`: the row's own colour,
  // not the link blue, and no underline on hover.
  control.value ? "block text-field hover:text-field hover:no-underline" : "",
  // `button.list-group-item`
  props.action ? "w-full text-left disabled:opacity-65" : "",
])
</script>

<template>
  <component :is="element" v-bind="bindings" :class="classes">
    <slot />
  </component>
</template>

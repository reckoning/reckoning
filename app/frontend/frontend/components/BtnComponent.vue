<template>
  <component
    :is="component"
    v-bind="buttonProps"
    :class="
      [baseClasses, focusClasses, sizes[props.size], colors[props.color]].flat()
    "
  >
    <slot />
  </component>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import type { RouteLocationRaw } from "vue-router";

export interface Props {
  to?: RouteLocationRaw | undefined;
  href?: string | undefined;
  size?: "xs" | "sm" | "md" | "default" | "lg";
  color?: "primary" | "secondary" | "success" | "danger" | "warning" | "info";
  buttonType?: "button" | "submit" | "reset";
}

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  size: "default",
  color: "primary",
  buttonType: "button",
});

const component = computed(() => {
  if (props.to) {
    return "router-link";
  } else if (props.href) {
    return "a";
  } else {
    return "button";
  }
});

const buttonProps = computed(() => {
  if (props.to) {
    return { to: props.to };
  } else if (props.href) {
    return { href: props.href };
  } else {
    return { type: props.buttonType };
  }
});

const sizes = {
  xs: ["rounded", "px-2.5", "py-1.5", "text-xs"],
  sm: ["rounded-md", "px-3", "py-2", "text-sm"],
  md: ["rounded-md", "px-4", "py-2", "text-sm"],
  default: ["rounded-md", "px-4", "py-2", "text-base"],
  lg: ["rounded-md", "px-6", "py-3", "text-base"],
};

const colors = {
  primary: [
    "border-transparent",
    "bg-brand-primary",
    "text-white",
    "hover:bg-brand-primaryDark",
    "focus:ring-brand-primaryDark",
  ],
  secondary: [
    "border-gray-300",
    "bg-white",
    "text-gray-700",
    "hover:bg-gray-50",
    "focus:ring-brand-primaryDark",
  ],
};

const focusClasses = [
  "focus:outline-none",
  "focus:ring-2",
  "focus:ring-offset-2",
];

const baseClasses = [
  // "inline-flex",
  "items-center",
  "border",
  "shadow-sm",
  "font-medium",
];
</script>

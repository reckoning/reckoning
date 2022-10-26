<template>
  <component
    :is="component"
    v-bind="buttonProps"
    :class="
      [
        baseClasses,
        focusClasses,
        sizes[props.size],
        colors[props.color],
        grouped[props.grouped],
        rounded[props.rounded],
      ].flat()
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
  color?:
    | "primary"
    | "secondary"
    | "success"
    | "danger"
    | "warning"
    | "info"
    | "clear";
  buttonType?: "button" | "submit" | "reset";
  grouped?: "default" | "left" | "right" | "both";
  rounded?: "default" | "full";
}

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  size: "default",
  color: "secondary",
  buttonType: "button",
  grouped: "default",
  rounded: "default",
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
  sm: ["rounded-md", "px-3", "py-2", "text-sm", "leading-4"],
  md: ["rounded-md", "px-4", "py-2", "text-sm"],
  default: ["rounded-md", "px-4", "py-2", "text-base"],
  lg: ["rounded-md", "px-6", "py-3", "text-base"],
};

const grouped = {
  default: [],
  left: ["rounded-l-none"],
  both: ["rounded-none", "border-r-0"],
  right: ["rounded-r-none", "border-r-0"],
};

const rounded = {
  default: [],
  full: [
    "rounded-full",
    "h-8",
    "w-8",
    "py-2",
    "px-2",
    "items-center",
    "justify-center",
  ],
};

const colors = {
  primary: [
    "border-transparent",
    "bg-brand-primary",
    "text-white",
    "hover:bg-brand-primaryDark",
    "shadow-sm",
  ],
  secondary: [
    "border-gray-300",
    "bg-white",
    "text-gray-700",
    "hover:bg-gray-100",
    "shadow-sm",
  ],
  success: [
    "border-transparent",
    "bg-green-500",
    "text-white",
    "hover:bg-green-700",
    "shadow-sm",
  ],
  danger: [],
  warning: [],
  info: [],
  clear: [
    "bg-transparent",
    "border-transparent",
    "shadow-none",
    "hover:bg-transparent",
  ],
};

const focusClasses = [
  "focus:outline-none",
  "focus:ring-2",
  "focus:ring-offset-2",
  "focus:z-10",
  "focus:ring-brand-primaryDark",
];

const baseClasses = ["inline-flex", "items-center", "border", "font-medium"];
</script>

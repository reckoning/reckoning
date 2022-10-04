<template>
  <component
    :is="component"
    v-bind="buttonProps"
    :class="[cssPosition, cssSize, cssColors, cssClasses].flat()"
  >
    <slot />
  </component>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import type { RouteLocationRaw } from "vue-router";

export interface Props {
  to?: RouteLocationRaw;
  href?: string;
}

const props = defineProps<Props>();

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
    return { type: "button" };
  }
});

const cssPosition = ["inline-flex"];

const cssSize = ["font-medium ", "text-sm", "px-4", "py-2"];

const cssColors = [
  "border-transparent",
  "bg-gray-600",
  "text-white",
  "hover:bg-gray-700",
  "focus:ring-indigo-500",
  "focus:ring-offset-gray-800",
];

const cssClasses = [
  "items-center",
  "rounded-md",
  "border",
  "shadow-sm",
  "focus:outline-none",
  "focus:ring-2",
  "focus:ring-offset-2",
];
</script>

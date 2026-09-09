<script setup lang="ts">
import { computed, useSlots } from "vue"

// `.input-group`: addons and a control welded into one outline. The addon is
// what the forms used instead of a label above the field, and the trailing
// one is how a percentage or a unit was printed after the number.
const props = withDefaults(defineProps<{addon?: string; addonAfter?: string}>(), {
  addon: undefined,
  addonAfter: undefined,
})

const slots = useSlots()

// Bootstrap rounds the outline on the outermost elements only, so the
// control keeps a corner on whichever side nothing is welded to it.
const leading = computed(() => Boolean(props.addon || slots.addon))
const trailing = computed(() => Boolean(props.addonAfter || slots.addonAfter || slots.button))

const ADDON =
  "flex items-center border border-field-border bg-addon px-3 text-base whitespace-nowrap text-field"
</script>

<template>
  <div class="flex">
    <span v-if="leading" :class="[ADDON, 'rounded-l-bs border-r-0']">
      <slot name="addon">{{ addon }}</slot>
    </span>

    <div
      class="grow"
      :class="[leading ? '[&>*]:rounded-l-none' : '', trailing ? '[&>*]:rounded-r-none' : '']"
    >
      <slot />
    </div>

    <span
      v-if="addonAfter || $slots.addonAfter"
      :class="[ADDON, 'rounded-r-bs border-l-0 -ml-px']"
    >
      <slot name="addonAfter">{{ addonAfter }}</slot>
    </span>

    <div v-if="$slots.button" class="[&>*]:rounded-l-none [&>*]:-ml-px">
      <slot name="button" />
    </div>
  </div>
</template>

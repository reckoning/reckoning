<script setup lang="ts">
// Bootstrap 3's `.panel.panel-default`: the box every server-rendered screen
// is built out of. `list` switches the heading to the tighter padding
// `partials/_panel-list.scss` gives a column-header row.
withDefaults(defineProps<{title?: string; list?: boolean}>(), {title: undefined, list: false})
</script>

<template>
  <div class="mb-5 rounded-bs border border-rule-strong bg-surface">
    <div
      v-if="title || $slots.heading"
      class="rounded-t-bs border-b border-rule-strong bg-surface-muted text-muted-strong"
      :class="list ? 'px-4 py-2' : 'px-4 py-2.5'"
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

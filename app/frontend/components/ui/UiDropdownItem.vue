<script setup lang="ts">
// One `.dropdown-menu li`. `active` carries the same left marker hovering
// gives, so the current filter value reads as chosen.
withDefaults(defineProps<{active?: boolean}>(), {active: false})
</script>

<template>
  <li>
    <div
      class="block cursor-pointer px-5 py-0.5 text-ink hover:bg-surface-muted hover:shadow-[inset_4px_0_0_var(--color-brand)]"
      :class="active ? 'bg-surface-muted shadow-[inset_4px_0_0_var(--color-brand)]' : ''"
      role="menuitem"
    >
      <slot />
    </div>
  </li>
</template>

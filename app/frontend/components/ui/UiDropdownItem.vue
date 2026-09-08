<script setup lang="ts">
// One `.dropdown-menu li`. `active` carries the same left marker hovering
// gives, so the current filter value reads as chosen.
withDefaults(defineProps<{active?: boolean}>(), {active: false})
</script>

<template>
  <li>
    <div
      class="bs-dropdown-item cursor-pointer"
      :class="active ? 'is-active' : ''"
      role="menuitem"
    >
      <slot />
    </div>
  </li>
</template>

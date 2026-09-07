<script setup lang="ts">
// `.list-group-item`. Rendered as a link it takes the hover fill Bootstrap
// gives `a.list-group-item`.
withDefaults(defineProps<{interactive?: boolean}>(), {interactive: false})
</script>

<template>
  <div class="px-4 py-2.5" :class="interactive ? 'hover:bg-surface-muted' : ''">
    <slot />
  </div>
</template>

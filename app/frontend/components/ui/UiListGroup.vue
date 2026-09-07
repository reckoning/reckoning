<script setup lang="ts">
// `.list-group` inside a panel: rows divided by the panel's own border, the
// last one rounding off the bottom corners.
</script>

<template>
  <div class="rounded-b-bs [&>*+*]:border-t [&>*+*]:border-rule-strong">
    <slot />
  </div>
</template>

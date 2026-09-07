<script setup lang="ts">
import { computed } from "vue"

// `.progress.progress-slim` with the bar coloured the way
// `ProjectHelper#budget_progress` colours it: green up to 70% of the budget,
// amber to 90%, red beyond.
const props = defineProps<{percent: number}>()

// Capped so an overrun cannot run off the row; the number beside it still
// tells the truth.
const width = computed(() => Math.min(Math.max(props.percent, 0), 100))

const fill = computed(() => {
  if (props.percent > 90) return "bg-danger"
  if (props.percent > 70) return "bg-warning"

  return "bg-success"
})
</script>

<template>
  <div class="h-3.5 overflow-hidden rounded-bs bg-surface-muted shadow-[inset_0_1px_2px_rgba(0,0,0,0.1)]">
    <div class="h-full" :class="fill" :style="{ width: `${width}%` }"></div>
  </div>
</template>

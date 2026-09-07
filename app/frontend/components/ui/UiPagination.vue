<script setup lang="ts">
// `.pagination` as Kaminari rendered it: bordered links sharing one rounded
// outline, and a full-width row of them on a narrow screen
// (`partials/_pagination.scss`).
defineProps<{page: number; hasNext: boolean; previousLabel: string; nextLabel: string}>()

const emit = defineEmits<{go: [number]}>()
</script>

<template>
  <nav class="flex" data-test="pagination">
    <button
      type="button"
      class="rounded-l-bs border border-rule-strong bg-surface px-3 py-1.5 text-brand hover:bg-rule disabled:text-muted disabled:opacity-65 max-sm:grow max-sm:text-center"
      :disabled="page === 1"
      data-test="prev-page"
      @click="emit('go', page - 1)"
    >
      {{ previousLabel }}
    </button>

    <span
      class="border-y border-rule-strong bg-surface px-3 py-1.5 text-ink tabular-nums max-sm:grow max-sm:text-center"
      data-test="page"
    >{{ page }}</span>

    <button
      type="button"
      class="rounded-r-bs border border-rule-strong bg-surface px-3 py-1.5 text-brand hover:bg-rule disabled:text-muted disabled:opacity-65 max-sm:grow max-sm:text-center"
      :disabled="!hasNext"
      data-test="next-page"
      @click="emit('go', page + 1)"
    >
      {{ nextLabel }}
    </button>
  </nav>
</template>

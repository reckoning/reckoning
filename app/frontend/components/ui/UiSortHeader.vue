<script setup lang="ts">
// One column label in a `panel-list` heading, as the `sortable` helper
// rendered it: a link that flips the direction. The arrow is the one addition
// — the helper marked the current column with a class the stylesheet never
// styled, so the list never showed what it was sorted by.
defineProps<{column: string; label: string; sort: string; direction: string}>()

const emit = defineEmits<{sort: [string]}>()
</script>

<template>
  <button
    type="button"
    class="text-left text-brand hover:underline"
    :data-test="`sort-${column}`"
    @click="emit('sort', column)"
  >
    {{ label }}
    <span v-if="sort === column" aria-hidden="true">{{ direction === "asc" ? "↑" : "↓" }}</span>
  </button>
</template>

<script setup lang="ts">
// Smoke-test Vue island. Confirms `.vue` SFC compilation + the
// mount machinery in `app/frontend/lib/mount-islands.ts` works
// end-to-end. Drop a `<div data-island="hello"></div>` anywhere
// in a view and the heading + counter button render.
//
// Real islands replace the AngularJS apps in Phase 6 — see
// docs/frontend-migration-plan.md.
import { ref } from "vue"

const props = defineProps<{ name?: string }>()
const count = ref(0)
</script>

<template>
  <div class="inline-flex items-center gap-3 rounded bg-emerald-50 border border-emerald-200 px-3 py-2 text-emerald-900">
    <span class="font-medium">Hello, {{ props.name ?? "Vue" }}</span>
    <button
      type="button"
      class="rounded bg-emerald-600 px-2 py-0.5 text-sm font-medium text-white hover:bg-emerald-500"
      @click="count++"
    >
      clicked {{ count }}×
    </button>
  </div>
</template>

<script setup lang="ts">
// Phase 6 scaffold for the timers-calendar island. Currently a
// placeholder — full feature parity with the legacy AngularJS
// `app/assets/javascripts/angular/timers_calendar/` happens in
// follow-up PRs:
//
// - month grid (weeks × days, with business-day highlight)
// - month-nav prev/next + jump-to-date
// - load timers from `GET /api/v1/projects/:id/timers?month=…`
// - click day → open timer modal (add/edit)
// - drag-reorder + autosave
//
// Until then, this component renders behind an env-based feature
// flag (`NEW_TIMERS_CALENDAR=1`) so the legacy AngularJS app
// keeps owning the screen in production while we land the Vue
// pieces incrementally.
//
// Props arrive from the `<div data-island-props>` JSON on the
// mount-point — see `app/views/projects/_timers_panel.html.erb`.
defineProps<{ projectId: string }>()
</script>

<template>
  <div class="rounded border border-dashed border-emerald-400 bg-emerald-50 p-6 text-emerald-900">
    <h3 class="text-lg font-medium">Timers calendar (Vue island)</h3>
    <p class="mt-1 text-sm">
      Phase 6 scaffold — feature parity with the AngularJS calendar is in flight.
      <code class="rounded bg-emerald-100 px-1">projectId={{ projectId }}</code>
    </p>
  </div>
</template>

<script setup lang="ts">
// Phase 6c scaffold for the timesheet island. Currently a
// placeholder — full feature parity with the legacy AngularJS
// `app/assets/javascripts/angular/timesheet/` happens in follow-up
// commits on this branch:
//
// - day view (card list of timers, inline start/stop, edit modal)
// - week view (7-column task grid with autosave cell editing)
// - URL state for date + view (`?date=YYYY-MM-DD&view=day|week`)
// - reuse TimerModal from the timers-calendar island
// - new TaskModal for week-view "+ Aufgabe hinzufügen"
//
// Until the port is complete, the island renders behind the
// Flipper feature `new_timesheet` (see ApplicationHelper#
// new_frontend?). Toggle on locally with:
//
//   bundle exec rails runner 'Flipper.enable(:new_timesheet)'

interface Labels {
  day: string
  week: string
  today: string
  addTimer: string
  addTask: string
  dayShort: string[]
  dayLong: string[]
}

defineProps<{
  locale?: string
  labels?: Labels
  monthLabels?: string[]
}>()
</script>

<template>
  <div class="col-xs-12">
    <div class="alert alert-info">
      <strong>Timesheet (Vue island)</strong> — Phase 6c scaffold. Day and week views land
      in follow-up commits on this branch.
    </div>
  </div>
</template>

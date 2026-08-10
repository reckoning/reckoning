<script setup lang="ts">
// Week view spreadsheet grid: 7-column day header, one row per
// task with editable per-day cells, footer with column + grand
// totals. Mirrors `app/views/templates/timesheets/week.html.erb`.
//
// Save logic (autosave on cell blur, see WeekCell):
//   - The cell emits the new `sumHours` for (task, date).
//   - We compute the delta against the existing timers for that
//     (task, date). With 0 new hours and a single existing timer,
//     we delete it. With a non-zero sum, we update the LAST
//     existing timer (preserving older ones, same as the legacy
//     `calculateTimerValue` rule) or create a new one if none.
//   - `useWeekTasks.refresh()` re-fetches after the operation
//     completes so the row + column totals reflect the truth.

import {computed, toRef} from "vue"
import dayjs from "dayjs"
import {useWeekTasks} from "../composables/useWeekTasks"
import {weekDays, formatHHMM, ISO_DATE, todayISO} from "../../../lib/timers/format"
import {createTimer, updateTimer, deleteTimer, type TaskWithTimers} from "../../../lib/timers/api"
import {confirmDialog} from "../../../lib/confirm"
import type {Timer} from "../../../lib/timers/types"
import WeekCell from "./WeekCell.vue"

const props = defineProps<{
  weekDate: string
  dayShortLabels: string[]
  addTaskLabel: string
  extraTasks?: TaskWithTimers[]
}>()

const emit = defineEmits<{
  addTask: []
  removeTask: [task: TaskWithTimers]
}>()

const weekDateRef = toRef(props, "weekDate")
const {tasks, loading, error, refresh} = useWeekTasks(weekDateRef)

// The API only returns tasks that already have timers in the week,
// so a freshly added task has no row to type into. Rows added this
// session are carried alongside until a save gives them timers and
// the fetch picks them up on its own.
const rows = computed<TaskWithTimers[]>(() => {
  const fetched = tasks.value
  const pending = (props.extraTasks ?? []).filter((e) => !fetched.some((t) => t.id === e.id))
  return [...fetched, ...pending]
})

const days = computed(() =>
  weekDays(props.weekDate).map((date) => {
    const d = dayjs(date, ISO_DATE)
    return {
      date,
      shortLabel: props.dayShortLabels[d.isoWeekday() - 1] ?? "",
      dayNumber: d.format("D."),
      isToday: date === todayISO(),
    }
  }),
)

function timersForDate(task: TaskWithTimers, date: string): Timer[] {
  return task.timers.filter((t) => t.date === date)
}

function taskTotal(task: TaskWithTimers): number {
  return task.timers.reduce((s, t) => s + (Number(t.value) || 0), 0)
}

function columnTotal(date: string): number {
  return rows.value.reduce(
    (s, task) => s + timersForDate(task, date).reduce((ss, t) => ss + (Number(t.value) || 0), 0),
    0,
  )
}

const grandTotal = computed(() =>
  rows.value.reduce((s, task) => s + taskTotal(task), 0),
)

async function onCellSave(payload: {
  date: string
  taskId: string
  sumHours: number
  existing: Timer[]
}) {
  const {date, taskId, sumHours, existing} = payload
  try {
    if (sumHours === 0) {
      // Delete all (typically one) existing timers for this cell.
      for (const t of existing) await deleteTimer(t.id)
    } else if (existing.length === 0) {
      await createTimer({date, value: sumHours, note: null, taskId}, false)
    } else {
      // Match the legacy `calculateTimerValue` rule: only the LAST
      // timer in the list absorbs the delta. Older same-date
      // timers stay as-is so historical breakdowns are preserved.
      const last = existing[existing.length - 1]
      const otherSum = existing
        .slice(0, -1)
        .reduce((s, t) => s + (Number(t.value) || 0), 0)
      const lastValue = Math.max(0, sumHours - otherSum)
      await updateTimer(last.id, {date, value: lastValue, note: last.note, taskId}, false)
    }
  } catch (e) {
    console.error("[timesheet] cell save failed:", e)
  } finally {
    refresh()
  }
}

async function onTaskRemove(task: TaskWithTimers) {
  if (!(await confirmDialog("Aufgabe und alle Zeiten dieser Woche löschen?"))) return
  try {
    for (const t of task.timers) {
      if (t.id) await deleteTimer(t.id)
    }
    emit("removeTask", task)
  } finally {
    refresh()
  }
}
</script>

<template>
  <div class="col-xs-12 timesheet-week-page" style="margin-top: 12px">
    <div v-if="error" class="alert alert-danger">
      Konnte Aufgaben nicht laden. <a role="button" @click.prevent="refresh">Erneut laden</a>
    </div>

    <div class="timesheet-header row">
      <div class="col-xs-12 col-md-4 timesheet-actions">
        <div class="btn-group btn-group-justified-responsive resource-nav">
          <a class="btn btn-primary" role="button" @click.prevent="emit('addTask')">
            <i class="fa fa-plus" aria-hidden="true"></i>
            {{ addTaskLabel }}
          </a>
        </div>
      </div>
      <div class="col-xs-12 col-md-6 timesheet-days">
        <div
          v-for="day in days"
          :key="day.date"
          class="timesheet-day"
          :class="{'timesheet-today': day.isToday}"
        >
          <a :href="`?date=${day.date}&view=day`">
            <span class="hidden-xs">{{ day.shortLabel }}</span>
            <br />
            <span>{{ day.dayNumber }}</span>
          </a>
        </div>
      </div>
    </div>

    <p v-if="loading && rows.length === 0" class="text-muted">Lade…</p>

    <div v-else-if="rows.length === 0" class="timesheet-blank text-center text-muted">
      <p>Diese Woche keine Aufgaben.</p>
    </div>

    <div v-for="task in rows" :key="task.id" class="panel panel-default">
      <div class="panel-body row">
        <div class="col-xs-12 col-md-4 timesheet-task">
          <a :href="`/projects/${task.projectId}`">{{ task.projectName }}</a>
          <small v-if="task.projectCustomerName"> | {{ task.projectCustomerName }}</small>
          <br />
          <span>{{ task.label }}</span>
        </div>
        <div class="col-xs-12 col-md-6 timesheet-days">
          <WeekCell
            v-for="day in days"
            :key="day.date"
            :date="day.date"
            :task-id="task.id"
            :timers-for-date="timersForDate(task, day.date)"
            @save="onCellSave"
          />
        </div>
        <div class="col-xs-3 col-xs-offset-7 col-md-offset-0 col-md-1">
          <div class="text-right timesheet-row-sum">
            <span class="tabular-nums">{{ formatHHMM(taskTotal(task)) }}</span>
          </div>
        </div>
        <div class="col-xs-2 col-md-1">
          <div class="text-right timesheet-task-actions">
            <button
              type="button"
              class="btn btn-link btn-lg default"
              title="Aufgabe löschen"
              @click="onTaskRemove(task)"
            >
              <i class="fa fa-close" aria-hidden="true"></i>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="rows.length > 0" class="timesheet-footer row">
      <div class="col-xs-12 col-md-offset-4 col-md-6 timesheet-days">
        <div
          v-for="day in days"
          :key="day.date"
          class="timesheet-day timesheet-col-sum"
        >
          <span class="tabular-nums">{{ formatHHMM(columnTotal(day.date)) }}</span>
        </div>
      </div>
      <div class="col-xs-12 col-md-1 timesheet-sum">
        <div class="text-right">
          <span class="tabular-nums">{{ formatHHMM(grandTotal) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

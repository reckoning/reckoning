<script setup lang="ts">
// Week view spreadsheet grid: 7-column day header, one row per task with
// editable per-day cells, footer with column + grand totals. Mirrors
// `app/views/templates/timesheets/week.html.erb`.
//
// Save logic (autosave on cell blur, see WeekCell):
//   - The cell emits the new `sumHours` for (task, date).
//   - We compute the delta against the existing timers for that
//     (task, date). With 0 new hours and a single existing timer,
//     we delete it. With a non-zero sum, we update the LAST
//     existing timer (preserving older ones, same as the legacy
//     `calculateTimerValue` rule) or create a new one if none.
//   - `useWeekTasks.refresh()` re-fetches after the operation
//     completes so the row and column totals reflect the truth.

import {computed, toRef} from "vue"
import {useI18n} from "vue-i18n"
import dayjs from "dayjs"
import {useWeekTasks} from "../composables/useWeekTasks"
import {weekDays, formatHHMM, ISO_DATE, todayISO} from "../../../lib/timers/format"
import {createTimer, updateTimer, deleteTimer, type TaskWithTimers} from "../../../lib/timers/api"
import {confirmDialog} from "../../../lib/confirm"
import type {Timer} from "../../../lib/timers/types"
import WeekCell from "./WeekCell.vue"
import UiButton from "../../../components/ui/UiButton.vue"

const { t } = useI18n()

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
// so a freshly added task has no grid grid-cols-12 items-center gap-2 to type into. Rows added this
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
  <div class="mt-3" data-test="week-grid">
    <div v-if="error" class="mb-2.5 rounded-bs border border-alert-danger-border bg-alert-danger px-4 py-3.5 text-alert-danger-text">
      {{ t("timesheet.tasksFailed") }}
      <a role="button" @click.prevent="refresh">{{ t("timesheet.retry") }}</a>
    </div>

    <div class="grid grid-cols-12 items-end gap-2 px-4 py-1.5">
      <div class="col-span-12 md:col-span-4">
        <UiButton variant="primary" class="max-md:w-full" @click="emit('addTask')">
          + {{ addTaskLabel }}
        </UiButton>
      </div>

      <div class="col-span-12 grid grid-cols-7 md:col-span-6">
        <div
          v-for="day in days"
          :key="day.date"
          class="px-px pb-1 pr-2 text-right"
          :class="day.isToday ? 'shadow-[inset_0_-4px_0_var(--color-brand)]' : ''"
        >
          <a :href="`?date=${day.date}&view=day`">
            <span class="max-sm:hidden">{{ day.shortLabel }}</span>
            <br />
            <span>{{ day.dayNumber }}</span>
          </a>
        </div>
      </div>
    </div>

    <p v-if="loading && rows.length === 0" class="text-muted">{{ t("timesheet.loading") }}</p>

    <div v-else-if="rows.length === 0" class="py-4 text-center text-muted">
      <p>{{ t("timesheet.noTasks") }}</p>
    </div>

    <div
      v-for="task in rows"
      :key="task.id"
      data-test="task-row"
      class="mb-2.5 rounded-bs border border-rule-strong bg-surface"
    >
      <div class="grid grid-cols-12 items-center gap-2 px-4 py-2.5">
        <div class="col-span-12 md:col-span-4" data-test="task-name">
          <a :href="`/projects/${task.projectId}`">{{ task.projectName }}</a>
          <small v-if="task.projectCustomerName" class="text-muted">
            | {{ task.projectCustomerName }}
          </small>
          <br />
          <span>{{ task.label }}</span>
        </div>

        <div class="col-span-12 grid grid-cols-7 md:col-span-6" data-test="week-cells">
          <WeekCell
            v-for="day in days"
            :key="day.date"
            :date="day.date"
            :task-id="task.id"
            :timers-for-date="timersForDate(task, day.date)"
            @save="onCellSave"
          />
        </div>

        <div
          class="col-span-3 col-start-8 text-right tabular-nums md:col-span-1 md:col-start-auto"
          data-test="row-sum"
        >
          {{ formatHHMM(taskTotal(task)) }}
        </div>

        <div class="col-span-2 text-right md:col-span-1">
          <button
            type="button"
            class="px-2 py-1 text-muted hover:text-ink"
            :title="t('timesheet.removeTask')"
            :data-test="`remove-task-${task.id}`"
            @click="onTaskRemove(task)"
          >
            <span aria-hidden="true">×</span>
          </button>
        </div>
      </div>
    </div>

    <div v-if="rows.length > 0" class="grid grid-cols-12 items-center gap-2 px-4 py-1.5">
      <div class="col-span-12 grid grid-cols-7 md:col-span-6 md:col-start-5">
        <div v-for="day in days" :key="day.date" class="px-px pr-3 text-right tabular-nums">
          {{ formatHHMM(columnTotal(day.date)) }}
        </div>
      </div>

      <div class="col-span-12 text-right tabular-nums md:col-span-1">
        {{ formatHHMM(grandTotal) }}
      </div>
    </div>
  </div>
</template>

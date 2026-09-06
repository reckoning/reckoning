<script setup lang="ts">
// The timesheet: day and week views, switched by the `?view=` query.
// Promoted from the Vue island it was in phase 6c — the labels it used to
// receive from Rails through `data-island-props` now come from vue-i18n, and
// the month and weekday names from `Intl`, which knows them for every locale
// the app might grow into.

import {computed, ref, watch} from "vue"
import {useI18n} from "vue-i18n"
import DayNav from "./components/DayNav.vue"
import DayView from "./components/DayView.vue"
import WeekGrid from "./components/WeekGrid.vue"
import TaskModal from "./components/TaskModal.vue"
import TimerModal from "./components/TimerModal.vue"
import {useTimesheetDate} from "./composables/useTimesheetDate"
import type {TaskWithTimers} from "@/lib/timers/api"
import type {Timer} from "@/lib/timers/types"

const {t, locale} = useI18n()

const labels = computed(() => ({
  day: t("timesheet.day"),
  week: t("timesheet.week"),
  today: t("timesheet.today"),
  addTimer: t("timesheet.addTimer"),
  editTimer: t("timesheet.editTimer"),
  addTask: t("timesheet.addTask"),
  dayShort: weekdayNames("short"),
  dayLong: weekdayNames("long"),
}))

// 2024-01-01 was a Monday, so seven days from there is one ISO week in the
// order the grid renders it.
function weekdayNames(width: "short" | "long"): string[] {
  const format = new Intl.DateTimeFormat(locale.value, {weekday: width})

  return Array.from({length: 7}, (_, index) => format.format(new Date(Date.UTC(2024, 0, 1 + index))))
}

const monthLabels = computed<string[]>(() => {
  const format = new Intl.DateTimeFormat(locale.value, {month: "long"})

  return Array.from({length: 12}, (_, index) => format.format(new Date(Date.UTC(2024, index, 1))))
})

const {date, view, weekStart, isToday, setView, prev, next, today, jump} = useTimesheetDate()

// Week-view task-add modal. `/api/v1/tasks?weekDate=` only returns
// tasks that already have timers in the week, so a task picked here
// is held as an extra grid grid-cols-12 items-center gap-2 until its first cell is filled in.
const showTaskModal = ref(false)
const addedTasks = ref<TaskWithTimers[]>([])

watch(weekStart, () => {
  addedTasks.value = []
})

function onAddTask() {
  showTaskModal.value = true
}

function onTaskCreated(task: TaskWithTimers) {
  if (!addedTasks.value.some((t) => t.id === task.id)) addedTasks.value.push(task)
}

function onRemoveTask(task: TaskWithTimers) {
  addedTasks.value = addedTasks.value.filter((t) => t.id !== task.id)
}

// Day-view timer modal. A null draft means closed; `date` alone is
// an add, a full timer is an edit.
const timerDraft = ref<(Partial<Timer> & {date: string}) | null>(null)
const dayViewRef = ref<InstanceType<typeof DayView> | null>(null)

function onAdd(forDate: string) {
  timerDraft.value = {date: forDate}
}

function onEdit(timer: Timer) {
  timerDraft.value = {...timer}
}

function onTimerSaved() {
  dayViewRef.value?.refresh()
}
</script>

<template>
  <div class="col-span-12">
    <DayNav
      :date="date"
      :view="view"
      :is-today="isToday"
      :day-long-labels="labels.dayLong"
      :month-labels="monthLabels"
      :today-label="labels.today"
      :day-label="labels.day"
      :week-label="labels.week"
      @prev="prev"
      @next="next"
      @today="today"
      @jump="jump"
      @view="setView"
    />

    <DayView
      v-if="view === 'day'"
      ref="dayViewRef"
      :date="date"
      :add-timer-label="labels.addTimer"
      @add="onAdd"
      @edit="onEdit"
    />

    <WeekGrid
      v-else
      :week-date="weekStart"
      :day-short-labels="labels.dayShort"
      :add-task-label="labels.addTask"
      :extra-tasks="addedTasks"
      @add-task="onAddTask"
      @remove-task="onRemoveTask"
    />

    <TaskModal
      v-if="showTaskModal"
      :title="labels.addTask"
      @close="showTaskModal = false"
      @created="onTaskCreated"
    />

    <TimerModal
      v-if="timerDraft"
      :draft="timerDraft"
      :add-title="labels.addTimer"
      :edit-title="labels.editTimer"
      @close="timerDraft = null"
      @saved="onTimerSaved"
    />
  </div>
</template>

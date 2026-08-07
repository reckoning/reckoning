<script setup lang="ts">
// Phase 6c root island for the timesheet. Switches between day
// and week views via the `?view=day|week` URL query param.

import {computed, ref, watch} from "vue"
import DayNav from "./components/DayNav.vue"
import DayView from "./components/DayView.vue"
import WeekGrid from "./components/WeekGrid.vue"
import TaskModal from "./components/TaskModal.vue"
import {useTimesheetDate} from "./composables/useTimesheetDate"
import type {TaskWithTimers} from "../../lib/timers/api"
import type {Timer} from "../../lib/timers/types"

interface Labels {
  day: string
  week: string
  today: string
  addTimer: string
  addTask: string
  dayShort: string[]
  dayLong: string[]
}

const props = defineProps<{
  locale?: string
  labels?: Labels
  monthLabels?: string[]
}>()

const labels = computed<Labels>(() => ({
  day: "Day",
  week: "Week",
  today: "Today",
  addTimer: "Add timer",
  addTask: "Add task",
  dayShort: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
  dayLong: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
  ...(props.labels ?? {}),
}))

const monthLabels = computed<string[]>(() =>
  props.monthLabels && props.monthLabels.length === 12
    ? props.monthLabels
    : [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ],
)

const {date, view, weekStart, isToday, setView, prev, next, today, jump} = useTimesheetDate()

// Week-view task-add modal. `/api/v1/tasks?weekDate=` only returns
// tasks that already have timers in the week, so a task picked here
// is held as an extra row until its first cell is filled in.
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

function onAdd(_date: string) {
  // Timer add/edit modal lands in a follow-up. Day view's
  // "Zeit hinzufügen" button is wired but no-op for now.
}

function onEdit(_timer: Timer) {
  // Same — modal is in a follow-up.
}
</script>

<template>
  <div class="col-xs-12">
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

    <DayView v-if="view === 'day'" :date="date" @add="onAdd" @edit="onEdit" />

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
  </div>
</template>

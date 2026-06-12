<script setup lang="ts">
// Phase 6c root island for the timesheet. Switches between day
// and week views via the `?view=day|week` URL query param.
//
// Day view: live, reads timers via `useDayTimers`.
// Week view: scaffold for the next commit on this branch.

import {computed} from "vue"
import DayNav from "./components/DayNav.vue"
import DayView from "./components/DayView.vue"
import {useTimesheetDate} from "./composables/useTimesheetDate"
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

const {date, view, isToday, setView, prev, next, today, jump} = useTimesheetDate()

function onAdd(_date: string) {
  // Modal lands in the next commit. For now the add button is
  // wired but does nothing visible — keeps the click target
  // present so layout / a11y don't change between commits.
}

function onEdit(_timer: Timer) {
  // Same as above — modal is the next commit.
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

    <div v-else class="row" style="margin-top: 12px">
      <div class="col-xs-12">
        <div class="alert alert-info">
          Week view — placeholder. Grid + autosave cell editing land in the next commit
          on this branch.
        </div>
      </div>
    </div>
  </div>
</template>

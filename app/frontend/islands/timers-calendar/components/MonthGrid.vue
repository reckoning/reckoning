<script setup lang="ts">
// Markup mirrors `app/views/templates/timers/month.html.erb` so the
// `_calendar.scss` partial applies. Classes used:
//   .calendar > .header > .day  (header row)
//   .calendar > .week  > .day { .current-month | .current-day }
//   .day > .day-number, .day > .timers > .timer / .add-timer

import {computed} from "vue"
import {buildWeeks} from "../calendar"
import type {Timer} from "../../../lib/timers/types"
import TimerBadge from "./TimerBadge.vue"

const props = defineProps<{
  month: string
  timers: Timer[]
  dayShortLabels: string[]
  addTimerTitle: string
}>()

const emit = defineEmits<{
  add: [date: string]
  edit: [timer: Timer]
}>()

const weeks = computed(() => buildWeeks(props.month))

const byDate = computed(() => {
  const map = new Map<string, Timer[]>()
  for (const t of props.timers) {
    const list = map.get(t.date) ?? []
    list.push(t)
    map.set(t.date, list)
  }
  return map
})
</script>

<template>
  <div class="calendar">
    <div class="header">
      <div v-for="(day, i) in dayShortLabels" :key="i" class="day">
        <span>{{ day }}</span>
      </div>
    </div>
    <div v-for="(week, wi) in weeks" :key="wi" class="week">
      <div
        v-for="cell in week.days"
        :key="cell.date"
        class="day"
        :class="{'current-month': cell.isCurrentMonth, 'current-day': cell.isCurrentDay}"
      >
        <a class="day-number" :href="`/timesheet/#/day/${cell.date}`" data-turbo="false">{{
          cell.day
        }}</a>
        <div class="timers">
          <TimerBadge
            v-for="timer in byDate.get(cell.date) ?? []"
            :key="timer.id"
            :timer="timer"
            @click="emit('edit', timer)"
          />
          <a
            class="add-timer"
            role="button"
            :title="addTimerTitle"
            @click.prevent="emit('add', cell.date)"
          >
            <i class="fa fa-plus" aria-hidden="true"></i>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

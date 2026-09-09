<script setup lang="ts">
// A month as seven columns per week, styled by the `.bs-calendar` classes
// `spa.css` measured out of `partials/_calendar.scss`.

import {computed} from "vue"
import {RouterLink} from "vue-router"
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
  <div class="bs-calendar">
    <div class="bs-calendar-header">
      <div v-for="(day, i) in dayShortLabels" :key="i" class="bs-calendar-day">
        <span>{{ day }}</span>
      </div>
    </div>
    <div v-for="(week, wi) in weeks" :key="wi" class="bs-calendar-week">
      <div
        v-for="cell in week.days"
        :key="cell.date"
        class="bs-calendar-day"
        :class="{
          'is-current-month': cell.isCurrentMonth,
          'is-current-day': cell.isCurrentDay,
        }"
      >
        <RouterLink class="bs-calendar-day-number" :to="{name: 'timesheet', query: {date: cell.date}}">
          {{ cell.day }}
        </RouterLink>
        <div>
          <TimerBadge
            v-for="timer in byDate.get(cell.date) ?? []"
            :key="timer.id"
            :timer="timer"
            @click="emit('edit', timer)"
          />
          <button
            type="button"
            class="bs-calendar-add text-brand hover:text-brand-hover"
            :title="addTimerTitle"
            @click="emit('add', cell.date)"
          >
            <i class="fa fa-plus" aria-hidden="true"></i>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

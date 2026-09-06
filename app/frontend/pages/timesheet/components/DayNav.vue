<script setup lang="ts">
// Mirrors the legacy
// `app/views/templates/timesheets/day.html.erb` /
// `week.html.erb` header — Bootstrap 3 `.btn-group` /
// `.resource-nav` so the existing styles apply.

import {computed, ref} from "vue"
import type {TimesheetView} from "../composables/useTimesheetDate"
import dayjs from "dayjs"
import {ISO_DATE} from "../../../lib/timers/format"

const props = defineProps<{
  date: string
  view: TimesheetView
  isToday: boolean
  dayLongLabels: string[]
  monthLabels: string[]
  todayLabel: string
  dayLabel: string
  weekLabel: string
}>()

const emit = defineEmits<{
  prev: []
  next: []
  today: []
  jump: [date: string]
  view: [view: TimesheetView]
}>()

const heading = computed(() => {
  if (props.view === "week") {
    const start = dayjs(props.date, ISO_DATE).startOf("isoWeek")
    const end = start.add(6, "day")
    return `${start.format("D.")} ${monthName(start.month())} – ${end.format("D.")} ${monthName(end.month())} ${end.year()}`
  }
  // day view
  const d = dayjs(props.date, ISO_DATE)
  const dayName = props.dayLongLabels[d.isoWeekday() - 1] ?? ""
  return `${dayName}, ${d.format("D.")} ${monthName(d.month())} ${d.year()}`
})

function monthName(idx: number): string {
  return props.monthLabels[idx] ?? ""
}

const inputValue = computed(() => props.date)
const hiddenInputRef = ref<HTMLInputElement | null>(null)

function openPicker() {
  const el = hiddenInputRef.value
  if (!el) return
  if (typeof el.showPicker === "function") el.showPicker()
  else {
    el.focus()
    el.click()
  }
}

function onDateInput(e: Event) {
  const value = (e.target as HTMLInputElement).value
  if (!value) return
  emit("jump", value)
}
</script>

<template>
  <div class="grid grid-cols-12 items-center gap-2">
    <div class="col-span-12 md:col-span-7">
      <h2>{{ heading }}</h2>
    </div>
    <div class="col-span-12 md:col-span-5">
      <div class="ml-auto resource-nav" style="display: flex; gap: 8px; flex-wrap: wrap">
        <div class="btn-group btn-group-justified-responsive resource-nav">
          <a class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60" role="button" @click.prevent="emit('prev')">
            <span aria-hidden="true">‹</span>
          </a>
          <a class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60 date-picker-trigger" role="button" @click.prevent="openPicker">
            <span aria-hidden="true">📅</span>
            <input
              ref="hiddenInputRef"
              type="date"
              :value="inputValue"
              class="date-picker-input"
              tabindex="-1"
              aria-hidden="true"
              @change="onDateInput"
            />
          </a>
          <a
            class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60"
            role="button"
            :class="{disabled: isToday}"
            @click.prevent="!isToday && emit('today')"
          >
            {{ todayLabel }}
          </a>
          <a class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60" role="button" @click.prevent="emit('next')">
            <span aria-hidden="true">›</span>
          </a>
        </div>
        <div class="btn-group">
          <a
            class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60"
            role="button"
            :class="{active: view === 'day'}"
            @click.prevent="emit('view', 'day')"
          >
            {{ dayLabel }}
          </a>
          <a
            class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60"
            role="button"
            :class="{active: view === 'week'}"
            @click.prevent="emit('view', 'week')"
          >
            {{ weekLabel }}
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.date-picker-trigger {
  position: relative;
}
.date-picker-input {
  position: absolute;
  inset: 0;
  opacity: 0;
  pointer-events: none;
  border: 0;
  background: transparent;
  z-index: -1;
}
</style>

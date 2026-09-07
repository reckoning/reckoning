<script setup lang="ts">
// Mirrors the legacy
// `app/views/templates/timesheets/day.html.erb` /
// `week.html.erb` header: the paging buttons and the day/week switch as two
// button groups, with the active view filled in.

import {computed, ref} from "vue"
import type {TimesheetView} from "../composables/useTimesheetDate"
import dayjs from "dayjs"
import {ISO_DATE} from "../../../lib/timers/format"

import { useI18n } from "vue-i18n"
import UiButton from "../../../components/ui/UiButton.vue"

const { t } = useI18n()

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
      <div class="flex flex-wrap justify-end gap-2">
        <!-- One `.btn-group`: the buttons share an outline, only the ends are
             rounded. -->
        <div class="flex [&>*:not(:first-child)]:-ml-px [&>*:not(:first-child)]:rounded-l-none [&>*:not(:last-child)]:rounded-r-none">
          <UiButton :title="t('timesheet.previousDay')" @click="emit('prev')">
            <span aria-hidden="true">‹</span>
          </UiButton>

          <UiButton class="date-picker-trigger" :title="t('timesheet.pickDate')" @click="openPicker">
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
          </UiButton>

          <UiButton :disabled="isToday" @click="!isToday && emit('today')">
            {{ todayLabel }}
          </UiButton>

          <UiButton :title="t('timesheet.nextDay')" @click="emit('next')">
            <span aria-hidden="true">›</span>
          </UiButton>
        </div>

        <div class="flex [&>*:not(:first-child)]:-ml-px [&>*:not(:first-child)]:rounded-l-none [&>*:not(:last-child)]:rounded-r-none">
          <UiButton :variant="view === 'day' ? 'primary' : 'default'" @click="emit('view', 'day')">
            {{ dayLabel }}
          </UiButton>
          <UiButton :variant="view === 'week' ? 'primary' : 'default'" @click="emit('view', 'week')">
            {{ weekLabel }}
          </UiButton>
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

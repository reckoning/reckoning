<script setup lang="ts">
// One spreadsheet cell in the week-view task grid.
//
// Mirrors the legacy `app/views/templates/timesheets/week.html.erb`
// per-day cell behavior. Three rendered states:
//
//   1. Invoiced → read-only display of `sumForTask`.
//   2. Running  → live duration (1 Hz tick from `startedAt`).
//   3. Editable → text input bound to a local string, saves on
//      blur via the parent. Empty / 0 input deletes; non-zero
//      input creates or updates the (single) timer for the
//      task+date.
//
// The cell talks to the parent (`WeekGrid`) via `save` /
// `delete` emits rather than calling the API itself — keeps the
// row-level total recompute in one place.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {formatHHMM, parseHHMM, runningDuration} from "../../../lib/timers/format"
import type {Timer} from "../../../lib/timers/types"

const props = defineProps<{
  date: string
  timersForDate: Timer[]
  taskId: string
}>()

const emit = defineEmits<{
  save: [{date: string; taskId: string; sumHours: number; existing: Timer[]}]
  remove: [timer: Timer]
}>()

const invoiced = computed(() => props.timersForDate.some((t) => !!t.positionId))
const runningTimer = computed(() => props.timersForDate.find((t) => t.started))
const sumHours = computed(() =>
  props.timersForDate.reduce((s, t) => s + (Number(t.value) || 0), 0),
)

const text = ref<string>(sumHours.value > 0 ? formatHHMM(sumHours.value) : "")
watch(sumHours, (next) => {
  // External update (refresh after save, cable broadcast in the day
  // view, etc.) — sync the input so the user sees the truth.
  text.value = next > 0 ? formatHHMM(next) : ""
})

// Running-timer 1 Hz tick.
const now = ref(Date.now())
let tickId: number | null = null
onMounted(() => {
  if (runningTimer.value) {
    tickId = window.setInterval(() => (now.value = Date.now()), 1000)
  }
})
onBeforeUnmount(() => {
  if (tickId !== null) window.clearInterval(tickId)
})
watch(runningTimer, (r) => {
  if (r && tickId === null) {
    tickId = window.setInterval(() => (now.value = Date.now()), 1000)
  } else if (!r && tickId !== null) {
    window.clearInterval(tickId)
    tickId = null
  }
})

const runningDisplay = computed(() => {
  const r = runningTimer.value
  if (!r || !r.startedAt) return null
  return runningDuration(r.startedAt, r.value, now.value)
})

function onBlur() {
  const next = parseHHMM(text.value)
  if (next === sumHours.value) return
  emit("save", {
    date: props.date,
    taskId: props.taskId,
    sumHours: next,
    existing: props.timersForDate,
  })
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === "Enter") {
    ;(e.target as HTMLInputElement).blur()
  }
}
</script>

<template>
  <div class="text-right timesheet-day">
    <div v-if="runningTimer" class="timesheet-timer started">
      <span data-test="running-spinner" class="inline-block animate-spin" aria-hidden="true">◌</span>
      <span class="tabular-nums">{{ runningDisplay }}</span>
    </div>
    <div v-else-if="invoiced" class="timesheet-timer invoiced">
      <span class="tabular-nums" :title="'On invoice'">{{ formatHHMM(sumHours) }}</span>
    </div>
    <div v-else class="timesheet-timer">
      <input
        v-model="text"
        type="text"
        class="block w-full rounded border border-field-border p-2 text-sm text-right"
        :placeholder="'0:00'"
        @blur="onBlur"
        @keydown="onKeydown"
      />
    </div>
  </div>
</template>

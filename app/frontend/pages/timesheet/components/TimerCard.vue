<script setup lang="ts">
// Mirrors one `.timesheet-timer-panel` from the legacy
// `app/views/templates/timesheets/day.html.erb` — a Bootstrap 3
// rounded border border-rule bg-surface with project + customer header, task label / note body,
// and the timer value (or running spinner) on the right.

import {computed, onBeforeUnmount, onMounted, ref} from "vue"
import {formatHHMM, runningDuration} from "../../../lib/timers/format"
import type {Timer} from "../../../lib/timers/types"

const props = defineProps<{timer: Timer}>()

const emit = defineEmits<{
  edit: []
}>()

const variant = computed<"running" | "invoiced" | "billable" | "">(() => {
  if (props.timer.started) return "running"
  if (props.timer.positionId) return "invoiced"
  if (props.timer.taskBillable) return "billable"
  return ""
})

const now = ref(Date.now())
let intervalId: number | null = null
onMounted(() => {
  if (props.timer.started) {
    intervalId = window.setInterval(() => (now.value = Date.now()), 1000)
  }
})
onBeforeUnmount(() => {
  if (intervalId !== null) window.clearInterval(intervalId)
})

const display = computed(() => {
  if (props.timer.started && props.timer.startedAt) {
    return runningDuration(props.timer.startedAt, props.timer.value, now.value)
  }
  return formatHHMM(props.timer.value)
})
</script>

<template>
  <div class="rounded border border-rule bg-surface timesheet-timer" :class="variant">
    <div class="p-3">
      <div class="grid grid-cols-12 items-center gap-2">
        <div class="col-span-12 md:col-span-9">
          <h3 class="timesheet-timer-project">
            <a :href="timer.links?.project?.href ?? `/projects/${timer.projectId}`">
              {{ timer.projectName }}
            </a>
            <small v-if="timer.projectCustomerName"> {{ timer.projectCustomerName }}</small>
          </h3>
          <div class="timesheet-timer-task">{{ timer.taskLabel }}</div>
          <div v-if="timer.note" class="timesheet-timer-note text-muted">{{ timer.note }}</div>
        </div>
        <div class="col-span-12 md:col-span-3 text-right">
          <div class="timesheet-timer-value">
            <span v-if="timer.started" class="inline-block animate-spin" aria-hidden="true">◌</span>
            <span class="tabular-nums">{{ display }}</span>
          </div>
          <button
            v-if="!timer.positionId"
            type="button"
            class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60 btn-sm"
            :title="'Edit'"
            @click="emit('edit')"
          >
            <span aria-hidden="true">✎</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

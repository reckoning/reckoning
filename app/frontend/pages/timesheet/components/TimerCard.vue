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
  <div class="mb-2.5 rounded-bs border border-rule-strong bg-surface" :class="variant">
    <div class="px-4 py-2.5">
      <div class="grid grid-cols-12 items-center gap-2">
        <div class="col-span-12 md:col-span-9">
          <h3>
            <a :href="timer.links?.project?.href ?? `/projects/${timer.projectId}`">
              {{ timer.projectName }}
            </a>
            <small v-if="timer.projectCustomerName" class="text-muted">
              {{ timer.projectCustomerName }}
            </small>
          </h3>
          <div>{{ timer.taskLabel }}</div>
          <div v-if="timer.note" class="text-muted">{{ timer.note }}</div>
        </div>
        <div class="col-span-12 flex items-center justify-end gap-2 md:col-span-3">
          <div :class="timer.started ? 'text-brand' : ''">
            <span v-if="timer.started" class="inline-block animate-spin" aria-hidden="true">◌</span>
            <span class="tabular-nums">{{ display }}</span>
          </div>
          <button
            v-if="!timer.positionId"
            type="button"
            class="rounded-bs-sm border border-field-border bg-surface px-2.5 py-1 text-small hover:border-control-hover-border hover:bg-control-hover disabled:opacity-65"
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

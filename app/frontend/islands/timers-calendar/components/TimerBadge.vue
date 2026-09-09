<script setup lang="ts">
// The chip a booked timer becomes in a day of the calendar. What it is —
// running, invoiced, billable — is the colour it carries.

import {computed, onBeforeUnmount, onMounted, ref} from "vue"
import {formatHHMM, runningDuration} from "../../../lib/timers/format"
import type {Timer} from "../../../lib/timers/types"

const props = defineProps<{timer: Timer}>()
defineEmits<{click: []}>()

const variant = computed(() => {
  if (props.timer.started) return "is-running"
  if (props.timer.positionId) return "is-invoiced"
  if (props.timer.taskBillable) return "is-billable"

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
  <a class="bs-calendar-timer" role="button" :class="variant" @click.stop.prevent="$emit('click')">
    <span v-if="timer.started"
      ><i class="fa fa-circle-o-notch fa-spin" aria-hidden="true"></i> {{ display }}</span
    >
    <span v-else class="timer-value">{{ display }}</span>
    |
    <span class="timer-task" :title="timer.taskName">{{ timer.taskName }}</span>
  </a>
</template>

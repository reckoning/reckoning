<script setup lang="ts">
// Renders the `<a class="timer">` chip from the legacy template
// (`app/views/templates/timers/month.html.erb`). Variant classes
// `billable` / `running` / `invoiced` are styled in
// `app/assets/stylesheets/partials/_calendar.scss`.

import {computed, onBeforeUnmount, onMounted, ref} from "vue"
import {formatHHMM, runningDuration} from "../format"
import type {Timer} from "../types"

const props = defineProps<{timer: Timer}>()
defineEmits<{click: []}>()

const variant = computed<"" | "billable" | "running" | "invoiced">(() => {
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
  <a class="timer" role="button" :class="variant" @click.stop.prevent="$emit('click')">
    <span v-if="timer.started"
      ><i class="fa fa-circle-o-notch fa-spin" aria-hidden="true"></i> {{ display }}</span
    >
    <span v-else class="timer-value">{{ display }}</span>
    |
    <span class="timer-task" :title="timer.taskName">{{ timer.taskName }}</span>
  </a>
</template>

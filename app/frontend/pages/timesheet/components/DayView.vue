<script setup lang="ts">
// Day view: list of timer cards for the selected day.
// Mirrors `app/views/templates/timesheets/day.html.erb`.

import {toRef} from "vue"
import {useDayTimers} from "../composables/useDayTimers"
import TimerCard from "./TimerCard.vue"
import type {Timer} from "../../../lib/timers/types"

const props = defineProps<{date: string; addTimerLabel: string}>()
const emit = defineEmits<{
  add: [date: string]
  edit: [timer: Timer]
}>()

const dateRef = toRef(props, "date")
const {timers, loading, error, refresh} = useDayTimers(dateRef)

defineExpose({refresh})
</script>

<template>
  <div class="grid grid-cols-12 items-center gap-2" style="margin-top: 12px">
    <div class="col-span-12 md:col-span-9">
      <div v-if="error" class="rounded border border-danger p-2 text-sm text-danger">
        Konnte Zeiten nicht laden. <a role="button" @click.prevent="refresh">Erneut laden</a>
      </div>

      <p v-if="loading && timers.length === 0" class="text-muted">Lade…</p>

      <div v-else-if="timers.length === 0" class="timesheet-blank text-center text-muted">
        <p>Keine Zeiten an diesem Tag.</p>
      </div>

      <TimerCard
        v-for="timer in timers"
        :key="timer.id"
        :timer="timer"
        @edit="emit('edit', timer)"
      />
    </div>
    <div class="col-span-12 md:col-span-3">
      <button
        type="button"
        class="rounded border border-brand-border bg-brand px-3 py-1 text-sm text-white hover:bg-brand-hover disabled:opacity-60 btn-block"
        @click="emit('add', date)"
      >
        <span aria-hidden="true">+</span>
        {{ addTimerLabel }}
      </button>
    </div>
  </div>
</template>

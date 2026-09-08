<script setup lang="ts">
// Day view: list of timer cards for the selected day.
// Mirrors `app/views/templates/timesheets/day.html.erb`.

import {toRef} from "vue"
import {useI18n} from "vue-i18n"
import {useDayTimers} from "../composables/useDayTimers"
import TimerCard from "./TimerCard.vue"
import UiButton from "../../../components/ui/UiButton.vue"
import type {Timer} from "../../../lib/timers/types"

const { t } = useI18n()

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
  <div class="mt-3 grid grid-cols-12 items-start gap-2">
    <div class="col-span-12 md:col-span-9">
      <div
        v-if="error"
        class="mb-2.5 rounded-bs border border-alert-danger-border bg-alert-danger px-4 py-3.5 text-alert-danger-text"
      >
        {{ t("timesheet.timersFailed") }}
        <a role="button" @click.prevent="refresh">{{ t("timesheet.retry") }}</a>
      </div>

      <p v-if="loading && timers.length === 0" class="text-muted">{{ t("timesheet.loading") }}</p>

      <div v-else-if="timers.length === 0" class="py-4 text-center text-muted">
        <p>{{ t("timesheet.noTimers") }}</p>
      </div>

      <TimerCard
        v-for="timer in timers"
        :key="timer.id"
        :timer="timer"
        @edit="emit('edit', timer)"
      />
    </div>

    <div class="col-span-12 md:col-span-3">
      <UiButton variant="primary" block @click="emit('add', date)">
        <i class="fa fa-plus"></i> {{ addTimerLabel }}
      </UiButton>
    </div>
  </div>
</template>

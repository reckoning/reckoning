<script setup lang="ts">
import {computed, onMounted, ref, shallowRef} from "vue"
import {useI18n} from "vue-i18n"
import MonthGrid from "./components/MonthGrid.vue"
import MonthNav from "./components/MonthNav.vue"
import TimerModal from "./components/TimerModal.vue"
import {useMonth} from "./composables/useMonth"
import {useTimers} from "./composables/useTimers"
import {listProjects} from "../../lib/timers/api"
import {businessDaysInMonth} from "../../lib/timers/format"
import type {Task, Timer} from "../../lib/timers/types"
import UiAlert from "../../components/ui/UiAlert.vue"
import UiButton from "../../components/ui/UiButton.vue"

const props = defineProps<{projectId: string}>()

const emit = defineEmits<{changed: []}>()

const {t, locale} = useI18n()

// The names of the days and the months come from the locale rather than from
// the catalogues, and the calendar reads them itself — the screen used to
// hand them in, from the days when a server-rendered page mounted this.
const labels = computed(() => ({
  weekDays: t("timersCalendar.weekDays"),
  today: t("timersCalendar.today"),
  addTimer: t("timersCalendar.addTimer"),
  dayShort: Array.from({length: 7}, (_, index) =>
    new Intl.DateTimeFormat(locale.value, {weekday: "short", timeZone: "UTC"}).format(
      new Date(Date.UTC(2024, 0, 1 + index)),
    ),
  ),
}))

const monthLabels = computed(() =>
  Array.from({length: 12}, (_, index) =>
    new Intl.DateTimeFormat(locale.value, {month: "long", timeZone: "UTC"}).format(
      new Date(Date.UTC(2024, index, 1)),
    ),
  ),
)

const {month, prev, next, today, set: setMonth} = useMonth()
const {timers, loading, error, refresh} = useTimers(props.projectId, month)

const tasks = ref<Task[]>([])
const tasksLoaded = ref(false)
onMounted(async () => {
  try {
    const projects = await listProjects()
    const project = projects.find((p) => p.id === props.projectId)
    tasks.value = project?.tasks ?? []
  } finally {
    tasksLoaded.value = true
  }
})

const modalDraft = shallowRef<(Partial<Timer> & {date: string; projectId: string}) | null>(null)

function openAdd(date: string) {
  modalDraft.value = {date, projectId: props.projectId}
}

function openEdit(timer: Timer) {
  modalDraft.value = {...timer}
}

function closeModal() {
  modalDraft.value = null
}

// On a successful modal save / delete, also re-render the host
// project show page so the stats panels above the calendar
// (`Erfasste Stunden`, `Verbleibende Stunden`, …) and the
// Highcharts budget diagram pick up the new timer value. The Vue
// island's month state is in `?month=` so re-mounting picks up
// where we left off.
//
// Drive visit, not full reload — Turbo will only swap the body
// HTML (cached if the URL was just visited). Skipped on the
// initial fetch from the `useTimers` watcher (which also calls
// `refresh()`) — that path arrives via the cable/network and
// shouldn't trigger a page refresh.
function onModalChanged() {
  refresh()
  emit("changed")
}

const businessDays = computed(() => businessDaysInMonth(month.value))
</script>

<template>
  <div data-test="timers-calendar">
    <MonthNav
      :month="month"
      :business-days="businessDays"
      :today-label="labels.today"
      :week-days-label="labels.weekDays"
      :month-labels="monthLabels"
      @prev="prev"
      @next="next"
      @today="today"
      @jump="setMonth"
    />

    <UiAlert v-if="error" variant="danger">
      {{ t("timesheet.timersFailed") }}
      <UiButton variant="link" class="px-0" @click="refresh">{{ t("timesheet.retry") }}</UiButton>
    </UiAlert>

    <MonthGrid
      :month="month"
      :timers="timers"
      :day-short-labels="labels.dayShort"
      :add-timer-title="labels.addTimer"
      @add="openAdd"
      @edit="openEdit"
    />
    <p v-if="loading" class="mt-1 text-right text-muted">{{ t("timesheet.loading") }}</p>

    <TimerModal
      v-if="modalDraft && tasksLoaded"
      :draft="modalDraft"
      :tasks="tasks"
      :project-id="projectId"
      @close="closeModal"
      @changed="onModalChanged"
    />
  </div>
</template>

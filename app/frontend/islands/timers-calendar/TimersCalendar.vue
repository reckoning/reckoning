<script setup lang="ts">
import {computed, onMounted, ref, shallowRef} from "vue"
import MonthGrid from "./components/MonthGrid.vue"
import MonthNav from "./components/MonthNav.vue"
import TimerModal from "./components/TimerModal.vue"
import {useMonth} from "./composables/useMonth"
import {useTimers} from "./composables/useTimers"
import {listProjects} from "./api"
import {businessDaysInMonth} from "./format"
import type {Task, Timer} from "./types"

interface Labels {
  weekDays: string
  today: string
  addTimer: string
  dayShort: string[]
}

const props = defineProps<{
  projectId: string
  labels?: Labels
  monthLabels?: string[]
}>()

const labels = computed<Labels>(() => ({
  weekDays: "weekdays",
  today: "Today",
  addTimer: "Add timer",
  dayShort: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
  ...(props.labels ?? {}),
}))

const monthLabels = computed<string[]>(() =>
  props.monthLabels && props.monthLabels.length === 12
    ? props.monthLabels
    : [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ],
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

const businessDays = computed(() => businessDaysInMonth(month.value))
</script>

<template>
  <div class="col-xs-12">
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

    <div v-if="error" class="alert alert-danger">
      Failed to load timers.
      <a role="button" @click.prevent="refresh">Retry</a>
    </div>

    <div class="row">
      <div class="col-xs-12">
        <MonthGrid
          :month="month"
          :timers="timers"
          :day-short-labels="labels.dayShort"
          :add-timer-title="labels.addTimer"
          @add="openAdd"
          @edit="openEdit"
        />
        <p v-if="loading" class="text-muted text-right" style="margin-top: 4px">Loading…</p>
      </div>
    </div>

    <TimerModal
      v-if="modalDraft && tasksLoaded"
      :draft="modalDraft"
      :tasks="tasks"
      :project-id="projectId"
      @close="closeModal"
      @changed="refresh"
    />
  </div>
</template>

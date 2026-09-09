<script setup lang="ts">
// Add / edit modal for the timesheet day view. Mirrors the legacy
// `app/views/templates/timesheets/modal/timer.html.erb`, which is
// project-scoped by a select rather than by the surrounding page —
// the timesheet spans every project the user books on.
//
// Bootstrap 3 modal markup so the existing `.modal-*` styles apply.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {useI18n} from "vue-i18n"
import {formatHHMM, isStartable, parseHHMM, runningDuration} from "../../../lib/timers/format"
import {
  createTask,
  createTimer,
  deleteTimer,
  listProjects,
  startTimer,
  stopTimer,
  updateTimer,
} from "../../../lib/timers/api"
import UiButton from "../../../components/ui/UiButton.vue"
import UiInput from "../../../components/ui/UiInput.vue"

import type {Project, Task, Timer} from "../../../lib/timers/types"
import {confirmDialog} from "../../../lib/confirm"

const { t } = useI18n()

const props = defineProps<{
  draft: Partial<Timer> & {date: string}
  addTitle: string
  editTitle: string
}>()

const emit = defineEmits<{
  close: []
  saved: []
}>()

const id = computed(() => props.draft.id)
const isEdit = computed(() => !!id.value)
const isInvoiced = computed(() => !!props.draft.positionId)
const isRunning = computed(() => !!props.draft.started)
const title = computed(() => (isEdit.value ? props.editTitle : props.addTitle))

const projects = ref<Project[]>([])
const projectsLoading = ref(true)
const projectId = ref<string>(props.draft.projectId ?? "")
const taskId = ref<string>(props.draft.taskId ?? "")
const note = ref<string>(props.draft.note ?? "")
const valueText = ref<string>(formatHHMM(props.draft.value ?? 0))
const date = ref<string>(props.draft.date)

const saving = ref(false)
const errorMessage = ref<string | null>(null)

const showCreateTask = ref(false)
const newTaskName = ref("")

const selectedProject = computed(() => projects.value.find((p) => p.id === projectId.value) ?? null)
const tasksForProject = computed<Task[]>(() => selectedProject.value?.tasks ?? [])

// Only reset the task once the user actually switches project —
// the initial load must not clear an edited timer's own task.
watch(projectId, (_next, prev) => {
  if (prev === "") return
  taskId.value = ""
  showCreateTask.value = false
})

const canSave = computed(() => !!taskId.value && !isInvoiced.value && !saving.value)
const canDelete = computed(() => isEdit.value && !isInvoiced.value && !saving.value)
const canStop = computed(() => isEdit.value && isRunning.value && !isInvoiced.value && !saving.value)
const canPlay = computed(
  () => !isInvoiced.value && !isRunning.value && !!taskId.value && !saving.value && isStartable(date.value),
)

const now = ref(Date.now())
let tickId: number | null = null

onMounted(async () => {
  if (isRunning.value) tickId = window.setInterval(() => (now.value = Date.now()), 1000)
  document.addEventListener("keydown", onKeydown)
  document.body.classList.add("modal-open")
  try {
    projects.value = await listProjects()
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    projectsLoading.value = false
  }
})

onBeforeUnmount(() => {
  if (tickId !== null) window.clearInterval(tickId)
  document.removeEventListener("keydown", onKeydown)
  document.body.classList.remove("modal-open")
})

function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") emit("close")
}

const runningDisplay = computed(() => {
  if (!isRunning.value || !props.draft.startedAt) return null
  return runningDuration(props.draft.startedAt, props.draft.value ?? 0, now.value)
})

function payload() {
  return {
    date: date.value,
    value: parseHHMM(valueText.value),
    note: note.value || null,
    taskId: taskId.value,
  }
}

async function persist(started: boolean) {
  saving.value = true
  errorMessage.value = null
  try {
    if (id.value) await updateTimer(id.value, payload(), started)
    else await createTimer(payload(), started)
    emit("saved")
    emit("close")
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

async function onSave() {
  await persist(false)
}

async function onPlay() {
  if (id.value && !isRunning.value) {
    saving.value = true
    try {
      await startTimer(id.value)
      emit("saved")
      emit("close")
    } catch (e) {
      errorMessage.value = errorText(e)
    } finally {
      saving.value = false
    }
    return
  }
  await persist(true)
}

async function onStop() {
  if (!id.value) return
  saving.value = true
  try {
    await stopTimer(id.value)
    emit("saved")
    emit("close")
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

async function onDelete() {
  if (!id.value) return
  if (!(await confirmDialog(t("timerModal.confirmDelete")))) return
  saving.value = true
  try {
    await deleteTimer(id.value)
    emit("saved")
    emit("close")
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

async function onCreateTaskInline() {
  const name = newTaskName.value.trim()
  if (!name || !projectId.value) return
  saving.value = true
  errorMessage.value = null
  try {
    const created = await createTask({projectId: projectId.value, name})
    if (selectedProject.value) {
      selectedProject.value.tasks = [...selectedProject.value.tasks, created as Task]
    }
    taskId.value = created.id
    newTaskName.value = ""
    showCreateTask.value = false
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

function errorText(e: unknown): string {
  return e instanceof Error ? e.message : t("timerModal.failed")
}
</script>

<template>
  <div>
    <div class="fixed inset-0 z-40 bg-ink/50"></div>
    <div
      class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4"
      tabindex="-1"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div class="relative z-50 mt-10 w-full max-w-lg" role="document">
        <div class="bs-modal">
          <div class="flex items-center justify-between border-b border-rule px-4 py-3.5">
            <h3>{{ title }}</h3>
            <button
              type="button"
              class="text-2xl leading-none opacity-20 hover:opacity-50"
              :aria-label="t('timerModal.close')"
              @click="emit('close')"
            >
              <span aria-hidden="true">&times;</span>
            </button>
          </div>

          <div class="px-4 py-3.5">
            <p
              v-if="isInvoiced"
              class="mb-4 rounded-bs border border-alert-success-border bg-alert-success px-4 py-3.5 text-alert-success-text"
            >
              {{ t("timerModal.invoiced") }}
            </p>

            <p v-if="projectsLoading" class="text-muted">{{ t("timerModal.loadingProjects") }}</p>

            <template v-else>
              <label class="mb-4 block">
                <span class="mb-1 inline-block font-bold">{{ t("timerModal.project") }}</span>
                <UiInput v-model="projectId" as="select" :disabled="isInvoiced">
                  <option value="">{{ t("timerModal.pickProject") }}</option>
                  <option v-for="p in projects" :key="p.id" :value="p.id">
                    {{ p.name }}{{ p.customerName ? ` — ${p.customerName}` : "" }}
                  </option>
                </UiInput>
              </label>

              <label class="mb-1 block">
                <span class="mb-1 inline-block font-bold">{{ t("timerModal.task") }}</span>
                <UiInput v-model="taskId" as="select" :disabled="isInvoiced || !projectId">
                  <option value="">{{ t("timerModal.pickTask") }}</option>
                  <option v-for="entry in tasksForProject" :key="entry.id" :value="entry.id">
                    {{ entry.name }}{{ entry.billable ? ` (${t("timerModal.billable")})` : "" }}
                  </option>
                </UiInput>
              </label>

              <div v-if="projectId && !isInvoiced" class="mb-4">
                <a v-if="!showCreateTask" role="button" @click.prevent="showCreateTask = true">
                  + {{ t("timerModal.newTask") }}
                </a>
                <div v-else class="flex">
                  <UiInput
                    v-model="newTaskName"
                    class="rounded-r-none"
                    :placeholder="t('timerModal.taskName')"
                    @keydown.enter.prevent="onCreateTaskInline"
                  />
                  <UiButton
                    variant="primary"
                    class="-ml-px rounded-none"
                    :disabled="!newTaskName.trim() || saving"
                    @click="onCreateTaskInline"
                  >
                    {{ t("timerModal.createTask") }}
                  </UiButton>
                  <UiButton class="-ml-px rounded-l-none" @click="showCreateTask = false">
                    {{ t("timerModal.cancel") }}
                  </UiButton>
                </div>
              </div>
            </template>

            <div class="grid grid-cols-12 items-start gap-2">
              <div class="col-span-12 md:col-span-8">
                <UiInput
                  v-model="note"
                  as="textarea"
                  rows="3"
                  :placeholder="t('timerModal.note')"
                  :disabled="isInvoiced"
                />
              </div>

              <div class="col-span-12 md:col-span-4">
                <!-- `.modal-timer`: the running time is the biggest thing on
                     the dialog. -->
                <div v-if="isRunning" class="text-right text-[28px] text-brand">
                  {{ runningDisplay }}
                </div>
                <UiInput
                  v-else
                  v-model="valueText"
                  class="h-[46px] text-right text-lg"
                  placeholder="0:00"
                  :disabled="isInvoiced"
                />
              </div>
            </div>

            <label v-if="!isInvoiced" class="mt-4 block">
              <span class="mb-1 inline-block font-bold">{{ t("timerModal.date") }}</span>
              <UiInput v-model="date" type="date" :disabled="isRunning" />
            </label>

            <p
              v-if="errorMessage"
              class="mt-4 rounded-bs border border-alert-danger-border bg-alert-danger px-4 py-3.5 text-alert-danger-text"
            >
              {{ errorMessage }}
            </p>
          </div>

          <div class="flex flex-wrap items-center gap-2 border-t border-rule px-4 py-3.5">
            <UiButton v-if="canDelete" variant="danger" @click="onDelete">
              {{ t("timerModal.delete") }}
            </UiButton>

            <div class="ml-auto flex flex-wrap gap-2">
              <UiButton @click="emit('close')">{{ t("timerModal.cancel") }}</UiButton>

              <UiButton v-if="canStop" :title="t('timerModal.stop')" @click="onStop">
                <span aria-hidden="true">■</span>
              </UiButton>

              <UiButton v-if="canPlay" :title="t('timerModal.start')" @click="onPlay">
                <span aria-hidden="true">▶</span>
              </UiButton>

              <UiButton v-if="!isInvoiced" variant="primary" :disabled="!canSave" @click="onSave">
                {{ t("timerModal.save") }}
              </UiButton>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Add / edit modal for the timesheet day view. Mirrors the legacy
// `app/views/templates/timesheets/modal/timer.html.erb`, which is
// project-scoped by a select rather than by the surrounding page —
// the timesheet spans every project the user books on.
//
// Bootstrap 3 modal markup so the existing `.modal-*` styles apply.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
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
import type {Project, Task, Timer} from "../../../lib/timers/types"
import {confirmDialog} from "../../../lib/confirm"

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
  if (!(await confirmDialog("Diese Zeit löschen?"))) return
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
  return e instanceof Error ? e.message : "Etwas ist schiefgelaufen."
}
</script>

<template>
  <div>
    <div class="fixed inset-0 z-40 bg-ink/40"></div>
    <div
      class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4"
      tabindex="-1"
      role="dialog"
      aria-modal="true"
      style="display: block"
      @click.self="emit('close')"
    >
      <div class="relative z-50 w-full max-w-lg" role="document">
        <div class="rounded border border-rule bg-surface shadow-lg">
          <div class="flex items-center justify-between border-b border-rule px-4 py-3">
            <button class="close" type="button" aria-label="Close" @click="emit('close')">
              <span aria-hidden="true">&times;</span>
            </button>
            <h2 class="text-base font-semibold">{{ title }}</h2>
          </div>

          <div class="px-4 py-3">
            <p v-if="isInvoiced" class="alert alert-success">
              Diese Zeit wurde bereits abgerechnet und kann nicht geändert werden.
            </p>

            <p v-if="projectsLoading" class="text-muted">Lade Projekte…</p>

            <template v-else>
              <div class="grid grid-cols-12 items-center gap-2">
                <div class="col-span-12">
                  <label class="block text-sm font-medium">Projekt</label>
                  <select v-model="projectId" class="block w-full rounded border border-field-border p-2 text-sm" :disabled="isInvoiced">
                    <option value="">— Projekt wählen —</option>
                    <option v-for="p in projects" :key="p.id" :value="p.id">
                      {{ p.name }}{{ p.customerName ? ` — ${p.customerName}` : "" }}
                    </option>
                  </select>
                </div>
              </div>

              <div class="grid grid-cols-12 items-center gap-2" style="margin-top: 12px">
                <div class="col-span-12">
                  <label class="block text-sm font-medium">Aufgabe</label>
                  <select
                    v-model="taskId"
                    class="block w-full rounded border border-field-border p-2 text-sm"
                    :disabled="isInvoiced || !projectId"
                  >
                    <option value="">— Aufgabe wählen —</option>
                    <option v-for="t in tasksForProject" :key="t.id" :value="t.id">
                      {{ t.name }}{{ t.billable ? " (fakturierbar)" : "" }}
                    </option>
                  </select>

                  <div v-if="projectId && !isInvoiced" style="margin-top: 6px">
                    <a v-if="!showCreateTask" role="button" @click.prevent="showCreateTask = true">
                      <span aria-hidden="true">+</span> Neue Aufgabe
                    </a>
                    <div v-else class="flex items-stretch gap-1">
                      <input
                        v-model="newTaskName"
                        type="text"
                        class="block w-full rounded border border-field-border p-2 text-sm"
                        placeholder="Name der Aufgabe"
                        @keydown.enter.prevent="onCreateTaskInline"
                      />
                      <span class="input-group-btn">
                        <button
                          type="button"
                          class="rounded border border-brand-border bg-brand px-3 py-1 text-sm text-white hover:bg-brand-hover disabled:opacity-60"
                          :disabled="!newTaskName.trim() || saving"
                          @click="onCreateTaskInline"
                        >
                          Anlegen
                        </button>
                        <button type="button" class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60" @click="showCreateTask = false">
                          Abbrechen
                        </button>
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </template>

            <div class="grid grid-cols-12 items-center gap-2" style="margin-top: 12px">
              <div class="col-span-12 md:col-span-8">
                <textarea
                  v-model="note"
                  class="block w-full rounded border border-field-border p-2 text-sm"
                  rows="3"
                  placeholder="Notiz"
                  :disabled="isInvoiced"
                ></textarea>
              </div>
              <div class="col-span-12 md:col-span-4">
                <br class="visible-sm visible-xs" />
                <div v-if="isRunning" class="modal-timer">
                  {{ runningDisplay }}
                </div>
                <input
                  v-else
                  v-model="valueText"
                  type="text"
                  class="input-lg block w-full rounded border border-field-border p-2 text-sm text-right"
                  placeholder="0:00"
                  :disabled="isInvoiced"
                />
              </div>
            </div>

            <div v-if="!isInvoiced" class="grid grid-cols-12 items-center gap-2">
              <div class="col-span-12" style="margin-top: 10px">
                <label class="block text-sm font-medium">Datum</label>
                <input v-model="date" type="date" class="block w-full rounded border border-field-border p-2 text-sm" :disabled="isRunning" />
              </div>
            </div>

            <p v-if="errorMessage" class="rounded border border-danger p-2 text-sm text-danger" style="margin-top: 12px">
              {{ errorMessage }}
            </p>
          </div>

          <div class="flex justify-end gap-2 border-t border-rule px-4 py-3">
            <div v-if="canDelete" class="pull-left">
              <button type="button" class="rounded border border-danger px-3 py-1 text-sm text-danger hover:bg-surface-muted" @click="onDelete">Löschen</button>
            </div>
            <div class="ml-auto">
              <button type="button" class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60 px-4 py-2" @click="emit('close')">
                Abbrechen
              </button>
              <button
                v-if="canStop"
                type="button"
                class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60 px-4 py-2"
                title="Stopp"
                @click="onStop"
              >
                <span aria-hidden="true">■</span>
              </button>
              <button
                v-if="canPlay"
                type="button"
                class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60 px-4 py-2"
                title="Start"
                @click="onPlay"
              >
                <span aria-hidden="true">▶</span>
              </button>
              <button
                v-if="!isInvoiced"
                type="button"
                class="rounded border border-brand-border bg-brand px-3 py-1 text-sm text-white hover:bg-brand-hover disabled:opacity-60 px-4 py-2"
                :disabled="!canSave"
                @click="onSave"
              >
                Speichern
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

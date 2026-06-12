<script setup lang="ts">
// Bootstrap 3 modal markup — mirrors the legacy
// `app/views/templates/timesheets/modal/timer.html.erb` so the
// existing `.modal-*` and `.btn-*` styles apply.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {formatHHMM, parseHHMM, runningDuration} from "../format"
import {createTask, createTimer, deleteTimer, startTimer, stopTimer, updateTimer} from "../api"
import type {Task, Timer} from "../types"

const props = defineProps<{
  draft: Partial<Timer> & {date: string; projectId: string}
  tasks: Task[]
  projectId: string
}>()

const emit = defineEmits<{
  close: []
  changed: []
}>()

const id = computed(() => props.draft.id)
const isEdit = computed(() => !!id.value)
const isInvoiced = computed(() => !!props.draft.positionId)
const isRunning = computed(() => !!props.draft.started)

const taskId = ref<string>(props.draft.taskId ?? "")
const note = ref<string>(props.draft.note ?? "")
const valueText = ref<string>(formatHHMM(props.draft.value ?? 0))
const date = ref<string>(props.draft.date)

const saving = ref(false)
const errorMessage = ref<string | null>(null)

const showCreateTask = ref(false)
const newTaskName = ref("")
const localTasks = ref<Task[]>([...props.tasks])

const canSave = computed(() => !!taskId.value && !isInvoiced.value && !saving.value)
const canDelete = computed(() => isEdit.value && !isInvoiced.value && !saving.value)
const canStop = computed(() => isEdit.value && isRunning.value && !isInvoiced.value && !saving.value)
const canPlay = computed(
  () => !isInvoiced.value && !isRunning.value && !!taskId.value && !saving.value,
)

const title = computed(() => (isEdit.value ? "Edit timer" : "Add timer"))

const now = ref(Date.now())
let tickId: number | null = null
onMounted(() => {
  if (isRunning.value) {
    tickId = window.setInterval(() => (now.value = Date.now()), 1000)
  }
  document.addEventListener("keydown", onKeydown)
  document.body.classList.add("modal-open")
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

async function persist(started: boolean): Promise<void> {
  saving.value = true
  errorMessage.value = null
  try {
    if (id.value) await updateTimer(id.value, payload(), started)
    else await createTimer(payload(), started)
    emit("changed")
    emit("close")
  } catch (e: unknown) {
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
      emit("changed")
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
    emit("changed")
    emit("close")
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

async function onDelete() {
  if (!id.value) return
  if (!window.confirm("Delete this timer?")) return
  saving.value = true
  try {
    await deleteTimer(id.value)
    emit("changed")
    emit("close")
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

async function onCreateTask() {
  const name = newTaskName.value.trim()
  if (!name) return
  saving.value = true
  try {
    const task = await createTask({projectId: props.projectId, name})
    localTasks.value.push(task as Task)
    taskId.value = task.id
    newTaskName.value = ""
    showCreateTask.value = false
  } catch (e) {
    errorMessage.value = errorText(e)
  } finally {
    saving.value = false
  }
}

function errorText(e: unknown): string {
  if (e instanceof Error) return e.message
  return "Something went wrong."
}

watch(
  () => props.tasks,
  (next) => {
    localTasks.value = [...next]
  },
)
</script>

<template>
  <div>
    <div class="modal-backdrop fade in"></div>
    <div
      class="modal fade in"
      tabindex="-1"
      role="dialog"
      aria-modal="true"
      style="display: block"
      @click.self="emit('close')"
    >
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <button class="close" type="button" aria-label="Close" @click="emit('close')">
              <span aria-hidden="true">&times;</span>
            </button>
            <h2 class="modal-title">{{ title }}</h2>
          </div>

          <div class="modal-body">
            <p v-if="isInvoiced" class="alert alert-success">
              This timer is on an invoice and can't be changed.
            </p>

            <div class="row">
              <div class="col-xs-12">
                <select
                  v-model="taskId"
                  class="form-control"
                  :disabled="isInvoiced"
                >
                  <option value="">— Select task —</option>
                  <option v-for="task in localTasks" :key="task.id" :value="task.id">
                    {{ task.name }}{{ task.billable ? " (billable)" : "" }}
                  </option>
                </select>

                <div v-if="!isInvoiced" style="margin-top: 6px">
                  <a v-if="!showCreateTask" role="button" @click.prevent="showCreateTask = true">
                    <i class="fa fa-plus"></i> New task
                  </a>
                  <div v-else class="input-group">
                    <input
                      v-model="newTaskName"
                      type="text"
                      class="form-control"
                      placeholder="New task name"
                      @keydown.enter.prevent="onCreateTask"
                    />
                    <span class="input-group-btn">
                      <button
                        type="button"
                        class="btn btn-primary"
                        :disabled="!newTaskName.trim() || saving"
                        @click="onCreateTask"
                      >
                        Create
                      </button>
                      <button
                        type="button"
                        class="btn btn-default"
                        @click="showCreateTask = false"
                      >
                        Cancel
                      </button>
                    </span>
                  </div>
                </div>

                <hr />
              </div>
            </div>

            <div class="row">
              <div class="col-xs-12 col-md-8">
                <textarea
                  v-model="note"
                  class="form-control"
                  rows="3"
                  placeholder="Note"
                  :disabled="isInvoiced"
                ></textarea>
              </div>
              <div class="col-xs-12 col-md-4">
                <br class="visible-sm visible-xs" />
                <div v-if="isRunning" class="modal-timer">
                  {{ runningDisplay }}
                </div>
                <input
                  v-else
                  v-model="valueText"
                  type="text"
                  class="input-lg form-control text-right"
                  placeholder="0:00"
                  :disabled="isInvoiced"
                />
              </div>
            </div>

            <div class="row" v-if="!isInvoiced">
              <div class="col-xs-12" style="margin-top: 10px">
                <label class="control-label">Date</label>
                <input
                  v-model="date"
                  type="date"
                  class="form-control"
                  :disabled="isRunning"
                />
              </div>
            </div>

            <p v-if="errorMessage" class="alert alert-danger" style="margin-top: 12px">
              {{ errorMessage }}
            </p>
          </div>

          <div class="modal-footer">
            <div class="pull-left" v-if="canDelete">
              <button type="button" class="btn btn-danger" @click="onDelete">
                Delete
              </button>
            </div>
            <div class="pull-right">
              <button type="button" class="btn btn-default btn-lg" @click="emit('close')">
                Cancel
              </button>
              <button
                v-if="canStop"
                type="button"
                class="btn btn-default btn-lg"
                title="Stop"
                @click="onStop"
              >
                <i class="fa fa-stop"></i>
              </button>
              <button
                v-if="canPlay"
                type="button"
                class="btn btn-default btn-lg"
                title="Play"
                @click="onPlay"
              >
                <i class="fa fa-play"></i>
              </button>
              <button
                v-if="!isInvoiced"
                type="button"
                class="btn btn-primary btn-lg"
                :disabled="!canSave"
                @click="onSave"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

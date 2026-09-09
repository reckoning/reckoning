<script setup lang="ts">
// Add / edit dialog for one day of a project's calendar. The timesheet's
// modal is the same dialog for a screen that spans every project, so it picks
// one; here the project is the one whose calendar is open.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {useI18n} from "vue-i18n"
import {formatHHMM, parseHHMM, runningDuration} from "../../../lib/timers/format"
import {createTask, createTimer, deleteTimer, startTimer, stopTimer, updateTimer} from "../../../lib/timers/api"
import type {Task, Timer} from "../../../lib/timers/types"
import {confirmDialog} from "../../../lib/confirm"
import UiButton from "../../../components/ui/UiButton.vue"
import UiInput from "../../../components/ui/UiInput.vue"

const {t} = useI18n()

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

const title = computed(() =>
  isEdit.value ? t("timesheet.editTimer") : t("timesheet.addTimer"),
)

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
  if (!(await confirmDialog(t("timerModal.confirmDelete")))) return
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
  return e instanceof Error ? e.message : t("timerModal.failed")
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

            <label class="mb-1 block">
              <span class="mb-1 inline-block font-bold">{{ t("timerModal.task") }}</span>
              <UiInput v-model="taskId" as="select" :disabled="isInvoiced">
                <option value="">{{ t("timerModal.pickTask") }}</option>
                <option v-for="task in localTasks" :key="task.id" :value="task.id">
                  {{ task.name }}{{ task.billable ? ` (${t("timerModal.billable")})` : "" }}
                </option>
              </UiInput>
            </label>

            <div v-if="!isInvoiced" class="mb-4">
              <a v-if="!showCreateTask" role="button" @click.prevent="showCreateTask = true">
                + {{ t("timerModal.newTask") }}
              </a>
              <div v-else class="flex">
                <UiInput
                  v-model="newTaskName"
                  class="rounded-r-none"
                  :placeholder="t('timerModal.taskName')"
                  @keydown.enter.prevent="onCreateTask"
                />
                <UiButton
                  variant="primary"
                  class="-ml-px rounded-none"
                  :disabled="!newTaskName.trim() || saving"
                  @click="onCreateTask"
                >
                  {{ t("timerModal.createTask") }}
                </UiButton>
                <UiButton class="-ml-px rounded-l-none" @click="showCreateTask = false">
                  {{ t("timerModal.cancel") }}
                </UiButton>
              </div>
            </div>

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

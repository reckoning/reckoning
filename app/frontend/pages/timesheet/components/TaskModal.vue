<script setup lang="ts">
// "+ Aufgabe hinzufügen" modal for the week view. Mirrors the
// legacy `app/views/templates/timesheets/modal/task.html.erb` but
// trimmed down: pick a project, pick or create a task, save. The
// user fills in cell values afterwards via the grid.
//
// Bootstrap 3 modal markup so the existing `.modal-*` styles apply.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {useI18n} from "vue-i18n"
import {createTask, listProjects, type TaskWithTimers} from "../../../lib/timers/api"
import type {Project, Task} from "../../../lib/timers/types"

import UiButton from "../../../components/ui/UiButton.vue"
import UiInput from "../../../components/ui/UiInput.vue"

const { t } = useI18n()

const props = defineProps<{
  title: string
}>()

const emit = defineEmits<{
  close: []
  created: [task: TaskWithTimers]
}>()

const projects = ref<Project[]>([])
const projectsLoading = ref(true)
const projectId = ref<string>("")
const taskId = ref<string>("")
const newTaskName = ref("")
const showCreate = ref(false)
const saving = ref(false)
const errorMessage = ref<string | null>(null)

onMounted(async () => {
  document.addEventListener("keydown", onKeydown)
  document.body.classList.add("modal-open")
  try {
    projects.value = await listProjects()
  } catch (e) {
    errorMessage.value = e instanceof Error ? e.message : "Failed to load projects."
  } finally {
    projectsLoading.value = false
  }
})

onBeforeUnmount(() => {
  document.removeEventListener("keydown", onKeydown)
  document.body.classList.remove("modal-open")
})

function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") emit("close")
}

const selectedProject = computed(() =>
  projects.value.find((p) => p.id === projectId.value) ?? null,
)
const tasksForProject = computed<Task[]>(() => selectedProject.value?.tasks ?? [])

// Reset task picker whenever the project changes.
watch(projectId, () => {
  taskId.value = ""
  showCreate.value = false
})

const canSave = computed(() => !!taskId.value && !saving.value)

async function onCreateTaskInline() {
  const name = newTaskName.value.trim()
  if (!name || !projectId.value) return
  saving.value = true
  errorMessage.value = null
  try {
    const created = await createTask({projectId: projectId.value, name})
    // Append to the cached project tasks so the dropdown updates.
    if (selectedProject.value) {
      selectedProject.value.tasks = [...selectedProject.value.tasks, created as Task]
    }
    taskId.value = created.id
    newTaskName.value = ""
    showCreate.value = false
  } catch (e) {
    errorMessage.value = e instanceof Error ? e.message : "Konnte Aufgabe nicht anlegen."
  } finally {
    saving.value = false
  }
}

function onSave() {
  const task = tasksForProject.value.find((t) => t.id === taskId.value)
  const project = selectedProject.value
  if (!task || !project) return
  emit("created", {
    id: task.id,
    name: task.name,
    label: task.label,
    billable: task.billable,
    projectId: project.id,
    projectName: project.name,
    projectCustomerName: project.customerName,
    timers: [],
  })
  emit("close")
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
            <p v-if="projectsLoading" class="text-muted">{{ t("timerModal.loadingProjects") }}</p>

            <template v-else>
              <label class="mb-4 block">
                <span class="mb-1 inline-block font-bold">{{ t("timerModal.project") }}</span>
                <UiInput v-model="projectId" as="select">
                  <option value="">{{ t("timerModal.pickProject") }}</option>
                  <option v-for="p in projects" :key="p.id" :value="p.id">
                    {{ p.name }}{{ p.customerName ? ` — ${p.customerName}` : "" }}
                  </option>
                </UiInput>
              </label>

              <label class="mb-1 block">
                <span class="mb-1 inline-block font-bold">{{ t("timerModal.task") }}</span>
                <UiInput v-model="taskId" as="select" :disabled="!projectId">
                  <option value="">{{ t("timerModal.pickTask") }}</option>
                  <option v-for="entry in tasksForProject" :key="entry.id" :value="entry.id">
                    {{ entry.name }}{{ entry.billable ? ` (${t("timerModal.billable")})` : "" }}
                  </option>
                </UiInput>
              </label>

              <div v-if="projectId" class="mb-4">
                <UiButton
                  v-if="!showCreate"
                  variant="link"
                  class="px-0"
                  @click="showCreate = true"
                >
                  + {{ t("timerModal.newTask") }}
                </UiButton>
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
                  <UiButton class="-ml-px rounded-l-none" @click="showCreate = false">
                    {{ t("timerModal.cancel") }}
                  </UiButton>
                </div>
              </div>
            </template>

            <p
              v-if="errorMessage"
              class="mt-4 rounded-bs border border-alert-danger-border bg-alert-danger px-4 py-3.5 text-alert-danger-text"
            >
              {{ errorMessage }}
            </p>
          </div>

          <div class="flex flex-wrap justify-end gap-2 border-t border-rule px-4 py-3.5">
            <UiButton @click="emit('close')">{{ t("timerModal.cancel") }}</UiButton>
            <UiButton variant="primary" :disabled="!canSave" @click="onSave">
              {{ t("taskModal.add") }}
            </UiButton>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

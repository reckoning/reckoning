<script setup lang="ts">
// "+ Aufgabe hinzufügen" modal for the week view. Mirrors the
// legacy `app/views/templates/timesheets/modal/task.html.erb` but
// trimmed down: pick a project, pick or create a task, save. The
// user fills in cell values afterwards via the grid.
//
// Bootstrap 3 modal markup so the existing `.modal-*` styles apply.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {createTask, listProjects, type TaskWithTimers} from "../../../lib/timers/api"
import type {Project, Task} from "../../../lib/timers/types"

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
            <p v-if="projectsLoading" class="text-muted">Lade Projekte…</p>

            <template v-else>
              <div class="grid grid-cols-12 items-center gap-2">
                <div class="col-span-12">
                  <label class="block text-sm font-medium">Projekt</label>
                  <select v-model="projectId" class="block w-full rounded border border-field-border p-2 text-sm">
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
                  <select v-model="taskId" class="block w-full rounded border border-field-border p-2 text-sm" :disabled="!projectId">
                    <option value="">— Aufgabe wählen —</option>
                    <option v-for="t in tasksForProject" :key="t.id" :value="t.id">
                      {{ t.name }}{{ t.billable ? " (fakturierbar)" : "" }}
                    </option>
                  </select>

                  <div v-if="projectId" style="margin-top: 6px">
                    <a v-if="!showCreate" role="button" @click.prevent="showCreate = true">
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
                        <button
                          type="button"
                          class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60"
                          @click="showCreate = false"
                        >
                          Abbrechen
                        </button>
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </template>

            <p v-if="errorMessage" class="rounded border border-danger p-2 text-sm text-danger" style="margin-top: 12px">
              {{ errorMessage }}
            </p>
          </div>

          <div class="flex justify-end gap-2 border-t border-rule px-4 py-3">
            <button type="button" class="rounded border border-field-border bg-surface px-3 py-1 text-sm hover:bg-control-hover disabled:opacity-60 px-4 py-2" @click="emit('close')">
              Abbrechen
            </button>
            <button
              type="button"
              class="rounded border border-brand-border bg-brand px-3 py-1 text-sm text-white hover:bg-brand-hover disabled:opacity-60 px-4 py-2"
              :disabled="!canSave"
              @click="onSave"
            >
              Hinzufügen
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

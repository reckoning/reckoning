<script setup lang="ts">
// "+ Aufgabe hinzufügen" modal for the week view. Mirrors the
// legacy `app/views/templates/timesheets/modal/task.html.erb` but
// trimmed down: pick a project, pick or create a task, save. The
// user fills in cell values afterwards via the grid.
//
// Bootstrap 3 modal markup so the existing `.modal-*` styles apply.

import {computed, onBeforeUnmount, onMounted, ref, watch} from "vue"
import {createTask, listProjects} from "../../../lib/timers/api"
import type {Project, Task} from "../../../lib/timers/types"

const props = defineProps<{
  title: string
}>()

const emit = defineEmits<{
  close: []
  created: [task: Task]
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
  if (!task) return
  emit("created", task)
  emit("close")
}
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
            <p v-if="projectsLoading" class="text-muted">Lade Projekte…</p>

            <template v-else>
              <div class="row">
                <div class="col-xs-12">
                  <label class="control-label">Projekt</label>
                  <select v-model="projectId" class="form-control">
                    <option value="">— Projekt wählen —</option>
                    <option v-for="p in projects" :key="p.id" :value="p.id">
                      {{ p.name }}{{ p.customerName ? ` — ${p.customerName}` : "" }}
                    </option>
                  </select>
                </div>
              </div>

              <div class="row" style="margin-top: 12px">
                <div class="col-xs-12">
                  <label class="control-label">Aufgabe</label>
                  <select v-model="taskId" class="form-control" :disabled="!projectId">
                    <option value="">— Aufgabe wählen —</option>
                    <option v-for="t in tasksForProject" :key="t.id" :value="t.id">
                      {{ t.name }}{{ t.billable ? " (fakturierbar)" : "" }}
                    </option>
                  </select>

                  <div v-if="projectId" style="margin-top: 6px">
                    <a v-if="!showCreate" role="button" @click.prevent="showCreate = true">
                      <i class="fa fa-plus" aria-hidden="true"></i> Neue Aufgabe
                    </a>
                    <div v-else class="input-group">
                      <input
                        v-model="newTaskName"
                        type="text"
                        class="form-control"
                        placeholder="Name der Aufgabe"
                        @keydown.enter.prevent="onCreateTaskInline"
                      />
                      <span class="input-group-btn">
                        <button
                          type="button"
                          class="btn btn-primary"
                          :disabled="!newTaskName.trim() || saving"
                          @click="onCreateTaskInline"
                        >
                          Anlegen
                        </button>
                        <button
                          type="button"
                          class="btn btn-default"
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

            <p v-if="errorMessage" class="alert alert-danger" style="margin-top: 12px">
              {{ errorMessage }}
            </p>
          </div>

          <div class="modal-footer">
            <button type="button" class="btn btn-default btn-lg" @click="emit('close')">
              Abbrechen
            </button>
            <button
              type="button"
              class="btn btn-primary btn-lg"
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

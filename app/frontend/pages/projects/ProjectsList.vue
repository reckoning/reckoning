<script setup lang="ts">
import { computed, ref } from "vue"
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useQueryClient } from "@tanstack/vue-query"
import {
  useProjects,
  useArchiveProject,
  useUnarchiveProject,
  getProjectsQueryKey,
} from "@/services/api/services/projects/projects"
import type { Project } from "@/services/api/models"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"

const { t, locale } = useI18n()
const toasts = useToastsStore()
const queryClient = useQueryClient()

const state = ref<"active" | "archived">("active")
const params = computed(() => ({ state: state.value }))

const { data: projects, isPending, isError } = useProjects(params)
const { mutateAsync: archive } = useArchiveProject()
const { mutateAsync: unarchive } = useUnarchiveProject()

// The ERB list groups by customer and sorts each group by name.
const grouped = computed(() => {
  const groups = new Map<string, Project[]>()

  for (const project of projects.value ?? []) {
    const key = project.customerName ?? t("projects.withoutCustomer")
    groups.set(key, [...(groups.get(key) ?? []), project])
  }

  return [...groups.entries()]
    .map(([customer, entries]) => ({
      customer,
      projects: [...entries].sort((a, b) => a.name.localeCompare(b.name)),
    }))
    .sort((a, b) => a.customer.localeCompare(b.customer))
})

const money = computed(
  () => new Intl.NumberFormat(locale.value, { style: "currency", currency: "EUR" }),
)
const hours = computed(
  () => new Intl.NumberFormat(locale.value, { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
)

function budgetOf(project: Project): number {
  return Number(project.budget ?? 0)
}

// The bar is capped at 100 so an overrun does not run off the row; the number
// beside it still tells the truth.
function progressOf(project: Project): number {
  const percent = Number(project.budgetPercent ?? 0)

  return Number.isFinite(percent) ? Math.min(Math.max(percent, 0), 100) : 0
}

async function refresh(): Promise<void> {
  await queryClient.invalidateQueries({ queryKey: getProjectsQueryKey(params.value) })
}

async function toggleArchive(project: Project): Promise<void> {
  const archived = project.workflowState === "archived"

  if (!archived && !(await confirmDialog(t("projects.confirmArchive")))) return

  try {
    if (archived) {
      await unarchive({ id: project.id })
      toasts.push("success", t("projects.unarchived"))
    } else {
      await archive({ id: project.id })
      toasts.push("success", t("projects.archived"))
    }
    await refresh()
  } catch {
    toasts.push("error", t("projects.actionFailed"))
  }
}
</script>

<template>
  <div class="p-4">
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-[24px] font-medium">
        {{ state === "archived" ? t("projects.titleArchived") : t("projects.title") }}
      </h1>

      <RouterLink
        :to="{ name: 'project-new' }"
        class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover"
        data-test="new-project"
      >
        {{ t("projects.new") }}
      </RouterLink>
    </div>

    <nav class="mb-4 flex gap-2" data-test="filters">
      <button
        type="button"
        class="rounded border border-field-border px-3 py-1 text-sm"
        :class="state === 'active' ? 'bg-brand text-white' : 'bg-surface'"
        data-test="filter-active"
        @click="state = 'active'"
      >
        {{ t("projects.filters.active") }}
      </button>
      <button
        type="button"
        class="rounded border border-field-border px-3 py-1 text-sm"
        :class="state === 'archived' ? 'bg-brand text-white' : 'bg-surface'"
        data-test="filter-archived"
        @click="state = 'archived'"
      >
        {{ t("projects.filters.archived") }}
      </button>
    </nav>

    <p v-if="isPending" data-test="loading">{{ t("projects.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("projects.loadFailed") }}</p>
    <p v-else-if="grouped.length === 0" data-test="empty">{{ t("projects.empty") }}</p>

    <div v-else class="flex flex-col gap-6" data-test="projects">
      <section v-for="group in grouped" :key="group.customer" class="border border-rule">
        <h2 class="border-b border-rule bg-surface-muted px-3 py-2 text-sm font-semibold">
          {{ group.customer }}
        </h2>

        <ul class="divide-y divide-rule">
          <li
            v-for="project in group.projects"
            :key="project.id"
            class="flex flex-wrap items-center gap-3 px-3 py-2"
            :data-test="`project-${project.id}`"
          >
            <a :href="`/projects/${project.id}`" class="min-w-40 grow font-medium text-brand">
              {{ project.name }}
            </a>

            <span v-if="budgetOf(project) > 0" class="w-28 text-right tabular-nums">
              {{ money.format(budgetOf(project)) }}
            </span>

            <span class="w-24 text-right tabular-nums" :data-test="`hours-${project.id}`">
              {{ hours.format(Number(project.timerValues ?? 0)) }} h
            </span>

            <span v-if="project.budgetPercent != null" class="h-2 w-24 rounded bg-surface-muted">
              <span
                class="block h-2 rounded bg-brand"
                :style="{ width: `${progressOf(project)}%` }"
                :data-test="`progress-${project.id}`"
              ></span>
            </span>

            <RouterLink
              :to="{ name: 'project-edit', params: { id: project.id } }"
              class="text-sm underline"
              :data-test="`edit-${project.id}`"
            >
              {{ t("projects.edit") }}
            </RouterLink>

            <button
              type="button"
              class="text-sm underline"
              :data-test="`archive-${project.id}`"
              @click="toggleArchive(project)"
            >
              {{ project.workflowState === "archived" ? t("projects.unarchive") : t("projects.archive") }}
            </button>
          </li>
        </ul>
      </section>
    </div>
  </div>
</template>

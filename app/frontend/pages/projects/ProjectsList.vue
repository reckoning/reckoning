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
import UiButton from "@/components/ui/UiButton.vue"
import UiDropdown from "@/components/ui/UiDropdown.vue"
import UiDropdownDivider from "@/components/ui/UiDropdownDivider.vue"
import UiDropdownItem from "@/components/ui/UiDropdownItem.vue"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiPanel from "@/components/ui/UiPanel.vue"
import UiProgress from "@/components/ui/UiProgress.vue"

const { t, locale } = useI18n()
const toasts = useToastsStore()
const queryClient = useQueryClient()

const state = ref<"active" | "archived">("active")
const params = computed(() => ({ state: state.value }))

const { data: projects, isPending, isError } = useProjects(params)
const { mutateAsync: archive } = useArchiveProject()
const { mutateAsync: unarchive } = useUnarchiveProject()

// The ERB list groups by customer and sorts each group by name. Keyed by id,
// not by the displayed name: nothing stops two customers of one account from
// sharing a name, and their projects are not one group.
const grouped = computed(() => {
  const groups = new Map<string, {id?: string; customer: string; projects: Project[]}>()

  for (const project of projects.value ?? []) {
    const key = project.customerId ?? "none"
    const group = groups.get(key) ?? {
      id: project.customerId ?? undefined,
      customer: project.customerName ?? t("projects.withoutCustomer"),
      projects: [],
    }

    group.projects.push(project)
    groups.set(key, group)
  }

  return [...groups.values()]
    .map((group) => ({
      ...group,
      projects: [...group.projects].sort((a, b) => a.name.localeCompare(b.name)),
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
  <div id="projects">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow">
        {{ state === "archived" ? t("projects.titleArchived") : t("projects.title") }}
      </h1>

      <div class="max-md:w-full">
        <RouterLink :to="{ name: 'project-new' }" data-test="new-project">
          <UiButton as="span" variant="primary" class="max-md:w-full">+ {{ t("projects.new") }}</UiButton>
        </RouterLink>
      </div>
    </div>

    <!-- One button that swaps the list, the way the server-rendered filter
         did: there are only the two states. -->
    <div class="mt-4" data-test="filters">
      <UiButton
        v-if="state === 'active'"
        data-test="filter-archived"
        @click="state = 'archived'"
      >
        {{ t("projects.filters.archived") }}
      </UiButton>
      <UiButton v-else data-test="filter-active" @click="state = 'active'">
        {{ t("projects.filters.active") }}
      </UiButton>
    </div>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("projects.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("projects.loadFailed") }}</p>
    <p v-else-if="grouped.length === 0" class="mt-4" data-test="empty">{{ t("projects.empty") }}</p>

    <div v-else class="mt-4" data-test="projects">
      <UiPanel
        v-for="group in grouped"
        :key="group.customer + group.projects[0].id"
        list
        data-test="customer-group"
      >
        <template #heading>
          <div class="grid grid-cols-12 items-center gap-2">
            <div class="col-span-8 md:col-span-4" data-test="customer-name">
              <a v-if="group.id" :href="`/customers/${group.id}/edit`" class="text-brand">
                <strong>{{ group.customer }}</strong>
              </a>
              <strong v-else>{{ group.customer }}</strong>
            </div>
            <div class="hidden md:col-span-2 md:block">{{ t("projects.columns.budget") }}</div>
            <div class="hidden md:col-span-4 md:block">{{ t("projects.columns.hours") }}</div>
            <div class="col-span-4 text-right md:col-span-2">
              <RouterLink
                v-if="group.id"
                :to="{ name: 'project-new', query: { customer_id: group.id } }"
                :title="t('projects.newFor', { customer: group.customer })"
                :data-test="`new-project-${group.id}`"
              >
                <UiButton as="span">+</UiButton>
              </RouterLink>
            </div>
          </div>
        </template>

        <UiListGroup>
          <UiListGroupItem
            v-for="project in group.projects"
            :key="project.id"
            :data-test="`project-${project.id}`"
          >
            <div class="grid grid-cols-12 items-center gap-y-2 gap-x-2">
              <div class="col-span-12 md:col-span-4">
                <a :href="`/projects/${project.id}`" class="text-ink hover:text-ink">
                  <b>{{ project.name }}</b>
                </a>
              </div>

              <div class="col-span-6 tabular-nums md:col-span-2">
                <b v-if="budgetOf(project) > 0">{{ money.format(budgetOf(project)) }}</b>
              </div>

              <div class="col-span-6 md:col-span-4">
                <UiProgress
                  v-if="budgetOf(project) > 0"
                  :percent="progressOf(project)"
                  :data-test="`progress-${project.id}`"
                />
                <span v-else class="tabular-nums" :data-test="`hours-${project.id}`">
                  {{ hours.format(Number(project.timerValues ?? 0)) }} h
                </span>
              </div>

              <div class="col-span-12 md:col-span-2 md:text-right">
                <UiDropdown align="right" class="max-md:!flex max-md:w-full">
                  <template #toggle="{ toggle }">
                    <UiButton
                      class="max-md:w-full"
                      :data-test="`actions-${project.id}`"
                      @click="toggle"
                    >
                      {{ t("projects.actions") }}
                      <span class="ml-1 inline-block border-t-4 border-r-4 border-l-4 border-transparent border-t-current"></span>
                    </UiButton>
                  </template>

                  <template #menu>
                    <UiDropdownItem>
                      <a :href="`/projects/${project.id}`">{{ t("projects.show") }}</a>
                    </UiDropdownItem>
                    <UiDropdownItem v-if="project.workflowState === 'active'">
                      <RouterLink
                        :to="{ name: 'invoice-new', query: { project_id: project.id } }"
                      >
                        + {{ t("projects.addInvoice") }}
                      </RouterLink>
                    </UiDropdownItem>
                    <UiDropdownItem>
                      <RouterLink
                        :to="{ name: 'project-edit', params: { id: project.id } }"
                        :data-test="`edit-${project.id}`"
                      >
                        {{ t("projects.edit") }}
                      </RouterLink>
                    </UiDropdownItem>
                    <UiDropdownDivider />
                    <UiDropdownItem>
                      <button
                        type="button"
                        :data-test="`archive-${project.id}`"
                        @click="toggleArchive(project)"
                      >
                        {{ project.workflowState === "archived" ? t("projects.unarchive") : t("projects.archive") }}
                      </button>
                    </UiDropdownItem>
                  </template>
                </UiDropdown>
              </div>
            </div>
          </UiListGroupItem>
        </UiListGroup>
      </UiPanel>
    </div>
  </div>
</template>

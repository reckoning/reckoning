<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import {
  useProject,
  useCreateProject,
  useUpdateProject,
  useDestroyProject,
} from "@/services/api/services/projects/projects"
import { useCustomers } from "@/services/api/services/customers/customers"
import { useAccount } from "@/services/api/services/account/account"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const id = computed(() => (route.params.id ? String(route.params.id) : undefined))
const editing = computed(() => id.value !== undefined)

const { data: customers } = useCustomers()
const { data: account } = useAccount()

// The ERB `new` action refused to render without an account address, because
// an invoice cannot be issued without one. The check has to live here now, or
// the guard would have quietly disappeared with the screen.
const missingAddress = computed(() => !editing.value && !(account.value?.address ?? "").trim())

// Editing has to wait for the record. Rendering the fields first looks
// harmless but is not: a task row added before the record arrives is wiped by
// the first fill, and the row the user typed into never existed as far as the
// form is concerned.
const loading = computed(() => editing.value && isPending.value)
const { data: project, isPending } = useProject(id.value ?? "", { query: { enabled: editing.value } })
const { mutateAsync: create } = useCreateProject()
const { mutateAsync: update } = useUpdateProject()
const { mutateAsync: destroy } = useDestroyProject()

// The values `Project::DEFAULT_ROUND_UP_OPTIONS` renders, in seconds, which
// is what the ERB select submitted.
const roundUpOptions = [0, 900, 1800, 3600] as const

// Tasks are edited inline, the way `fields_for :tasks` did it. A row the user
// removes keeps its id and travels with `_destroy`, since that is how the
// endpoint deletes one; a row that never had an id is simply dropped.
interface TaskRow {
  id?: string
  name: string
  billable: boolean
  destroyed: boolean
}

const tasks = ref<TaskRow[]>([])

// `rate`, `budget` and `budget_hours` are NOT NULL with a 0.0 default, so
// blank cannot mean null the way it does for a customer's payment period. It
// means "leave it alone": the key is dropped rather than sent, and a real
// zero is typed as one.
const decimal = z
  .union([z.literal("").transform(() => undefined), z.coerce.number().nonnegative().transform(String)])
  .optional()

const schema = toTypedSchema(
  z.object({
    name: z.string().min(1),
    // `belongs_to :customer` is required, so the server refuses a project
    // without one. Saying so here beats a submit that silently does nothing.
    customer_id: z.string().uuid(),
    round_up: decimal,
    rate: decimal,
    budget: decimal,
    budget_hours: decimal,
    budget_on_dashboard: z.boolean().optional(),
    invoice_addition: z.string().optional(),
    start_date: z.string().optional(),
    end_date: z.string().optional(),
  }),
)

// `new_project_path(customer_id: customer)` in the server-rendered list: the
// plus button in a customer's panel heading opens the form with that customer
// already chosen. The query carries it here.
const customerFromQuery = computed(() =>
  typeof route.query.customer_id === "string" ? route.query.customer_id : undefined,
)

const { defineField, handleSubmit, errors, setValues } = useForm({
  validationSchema: schema,
  initialValues: { budget_on_dashboard: true, customer_id: customerFromQuery.value },
})

const [name, nameAttrs] = defineField("name")
const [customerId, customerIdAttrs] = defineField("customer_id")
const [roundUp, roundUpAttrs] = defineField("round_up")
const [rate, rateAttrs] = defineField("rate")
const [budget, budgetAttrs] = defineField("budget")
const [budgetHours, budgetHoursAttrs] = defineField("budget_hours")
const [budgetOnDashboard, budgetOnDashboardAttrs] = defineField("budget_on_dashboard")
const [invoiceAddition, invoiceAdditionAttrs] = defineField("invoice_addition")
const [startDate, startDateAttrs] = defineField("start_date")
const [endDate, endDateAttrs] = defineField("end_date")

function normalizeRoundUp(value: string | null | undefined): string {
  const seconds = Number(value)

  return roundUpOptions.some((option) => option === seconds) ? String(seconds) : ""
}

// The API speaks date-time; the input speaks date.
function toDateInput(value: string | null | undefined): string {
  return value ? value.slice(0, 10) : ""
}

function toDateTime(value: string | undefined): string | null {
  return value ? new Date(`${value}T00:00:00Z`).toISOString() : null
}

// Only the first answer for a given project fills the form. vue-query refetches
// — on window focus, on reconnect — and re-running this would throw away
// whatever the user has typed since, including a task row they just added.
const filledFrom = ref<string | undefined>()

watch(
  project,
  (loaded) => {
    if (!loaded) return
    if (filledFrom.value === loaded.id) return

    filledFrom.value = loaded.id

    setValues({
      name: loaded.name,
      customer_id: loaded.customerId ?? undefined,
      rate: loaded.rate ?? "",
      budget: loaded.budget ?? "",
      budget_hours: loaded.budgetHours ?? "",
      budget_on_dashboard: loaded.budgetOnDashboard ?? true,
      // Stored as a decimal ("900.0"), offered as an option value ("900").
      // The ERB compared numerically for the same reason. A value that
      // matches no option — the 10.0 column default, which no option ever
      // wrote — leaves the select blank and stays untouched on save.
      round_up: normalizeRoundUp(loaded.roundUp),
      invoice_addition: loaded.invoiceAddition ?? "",
      start_date: toDateInput(loaded.startDate),
      end_date: toDateInput(loaded.endDate),
    })

    tasks.value = (loaded.tasks ?? []).map((task) => ({
      id: task.id,
      name: task.name ?? "",
      billable: task.billable ?? true,
      destroyed: false,
    }))
  },
  { immediate: true },
)

async function removeProject(): Promise<void> {
  if (!id.value) return
  if (!(await confirmDialog(t("project.confirmDelete")))) return

  try {
    await destroy({ id: id.value })
    toasts.push("success", t("project.deleted"))
    await router.push({ name: "projects" })
  } catch {
    // The endpoint refuses a project that still has invoices, which is the
    // usual reason this fails.
    toasts.push("error", t("project.deleteFailed"))
  }
}

function addTask(): void {
  tasks.value.push({ name: "", billable: true, destroyed: false })
}

function removeTask(index: number): void {
  const task = tasks.value[index]

  if (task.id) {
    task.destroyed = true
    return
  }

  tasks.value.splice(index, 1)
}

const visibleTasks = computed(() =>
  tasks.value.map((task, index) => ({ task, index })).filter(({ task }) => !task.destroyed),
)

function tasksAttributes() {
  return tasks.value
    .filter((task) => task.id || task.name.trim() !== "")
    .map((task) => ({
      ...(task.id ? { id: task.id } : {}),
      name: task.name,
      billable: task.billable,
      ...(task.destroyed ? { _destroy: true } : {}),
    }))
}

const save = handleSubmit(async (values) => {
  const data = {
    ...values,
    start_date: toDateTime(values.start_date),
    end_date: toDateTime(values.end_date),
    tasks_attributes: tasksAttributes(),
  }

  try {
    const saved = editing.value
      ? await update({ id: id.value as string, data })
      : await create({ data })

    toasts.push("success", editing.value ? t("project.saved") : t("project.created"))
    await router.push({ name: "project-edit", params: { id: saved.id } })
  } catch {
    toasts.push("error", t("project.saveFailed"))
  }
})

// These fields carry VeeValidate's own bindings rather than going through
// `UiInput`, so they name the shape's class themselves.
const FIELD = "bs-input"
</script>

<template>
  <div id="project">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="project-title">
        {{ editing ? project?.name : t("project.newTitle") }}
      </h1>

      <div class="flex flex-wrap gap-2 max-md:w-full max-md:flex-col">
        <UiButton
          v-if="editing"
          variant="danger"
          type="button"
          data-test="delete"
          @click="removeProject"
        >
          {{ t("project.delete") }}
        </UiButton>
        <RouterLink :to="{ name: 'projects' }" data-test="back">
          <UiButton as="span" class="max-md:w-full">{{ t("project.back") }}</UiButton>
        </RouterLink>
      </div>
    </div>

    <p v-if="loading" class="mt-4" data-test="loading">{{ t("project.loading") }}</p>

    <UiAlert v-else-if="missingAddress" variant="warning" class="mt-4" data-test="missing-address">
      {{ t("project.missingAddress") }}
      <a href="/settings#address" data-test="account-settings">{{ t("project.toSettings") }}</a>
    </UiAlert>

    <form v-else class="mt-4 max-w-3xl" @submit="save">
      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.customer") }}</span>
        <select v-model="customerId" v-bind="customerIdAttrs" data-test="customer" :class="FIELD">
          <option value="">{{ t("project.fields.noCustomer") }}</option>
          <option v-for="customer in customers ?? []" :key="customer.id" :value="customer.id">
            {{ customer.name }}
          </option>
        </select>
        <span v-if="errors.customer_id" data-test="customer-error" class="mt-1 block text-danger-text">
          {{ errors.customer_id }}
        </span>
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.name") }}</span>
        <input v-model="name" v-bind="nameAttrs" type="text" data-test="name" :class="FIELD" />
        <span v-if="errors.name" data-test="name-error" class="mt-1 block text-danger-text">{{ errors.name }}</span>
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.rate") }}</span>
        <input v-model="rate" v-bind="rateAttrs" type="number" step="0.01" min="0" data-test="rate" :class="FIELD" />
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.budget") }}</span>
        <input v-model="budget" v-bind="budgetAttrs" type="number" step="0.01" min="0" data-test="budget" :class="FIELD" />
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.budgetHours") }}</span>
        <input v-model="budgetHours" v-bind="budgetHoursAttrs" type="number" step="0.01" min="0" data-test="budget-hours" :class="FIELD" />
      </label>

      <label class="mb-4 flex items-center gap-2">
        <input v-model="budgetOnDashboard" v-bind="budgetOnDashboardAttrs" type="checkbox" data-test="budget-on-dashboard" class="size-4 accent-brand" />
        {{ t("project.fields.budgetOnDashboard") }}
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.roundUp") }}</span>
        <select v-model="roundUp" v-bind="roundUpAttrs" data-test="round-up" :class="FIELD">
          <option v-for="option in roundUpOptions" :key="option" :value="String(option)">
            {{ t(`project.roundUp.${option}`) }}
          </option>
        </select>
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.startDate") }}</span>
        <input v-model="startDate" v-bind="startDateAttrs" type="date" data-test="start-date" :class="FIELD" />
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.endDate") }}</span>
        <input v-model="endDate" v-bind="endDateAttrs" type="date" data-test="end-date" :class="FIELD" />
      </label>

      <label class="mb-4 block">
        <span class="mb-1 inline-block font-bold">{{ t("project.fields.invoiceAddition") }}</span>
        <textarea v-model="invoiceAddition" v-bind="invoiceAdditionAttrs" rows="4" data-test="invoice-addition" :class="FIELD"></textarea>
      </label>

      <UiPanel :title="t('project.tasks')">
        <template #body>
        <div class="flex flex-col gap-2" data-test="tasks">
          <div v-for="{ task, index } in visibleTasks" :key="task.id ?? `new-${index}`" class="flex flex-wrap items-center gap-2">
            <input
              v-model="task.name"
              type="text"
              :placeholder="t('project.fields.taskName')"
              :data-test="`task-name-${index}`"
              :class="FIELD"
            />
            <label class="flex items-center gap-1 whitespace-nowrap">
              <input v-model="task.billable" type="checkbox" :data-test="`task-billable-${index}`" class="size-4 accent-brand" />
              {{ t("project.fields.billable") }}
            </label>
            <UiButton
              type="button"
              variant="danger"
              :data-test="`task-remove-${index}`"
              @click="removeTask(index)"
            >
              ×
            </UiButton>
          </div>
        </div>

          <UiButton type="button" class="mt-4" data-test="add-task" @click="addTask">
            + {{ t("project.addTask") }}
          </UiButton>
        </template>
      </UiPanel>

      <UiFormActions
        :save-label="t('project.save')"
        :cancel-label="t('project.cancel')"
        @cancel="router.push({ name: 'projects' })"
      />
    </form>
  </div>
</template>

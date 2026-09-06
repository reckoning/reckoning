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
const { data: project } = useProject(id.value ?? "", { query: { enabled: editing.value } })
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

const { defineField, handleSubmit, errors, setValues } = useForm({
  validationSchema: schema,
  initialValues: { budget_on_dashboard: true },
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

watch(
  project,
  (loaded) => {
    if (!loaded) return

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
</script>

<template>
  <div class="p-4">
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-[24px] font-medium" data-test="project-title">
        {{ editing ? project?.name : t("project.newTitle") }}
      </h1>

      <div class="flex gap-3">
        <RouterLink :to="{ name: 'projects' }" class="text-sm underline" data-test="back">
          {{ t("project.back") }}
        </RouterLink>
        <button v-if="editing" type="button" class="text-sm text-danger underline" data-test="delete" @click="removeProject">
          {{ t("project.delete") }}
        </button>
      </div>
    </div>

    <p v-if="missingAddress" class="max-w-2xl border border-warning-border bg-warning p-3 text-sm text-white" data-test="missing-address">
      {{ t("project.missingAddress") }}
      <a href="/settings#address" class="underline" data-test="account-settings">{{ t("project.toSettings") }}</a>
    </p>

    <form v-else class="flex max-w-2xl flex-col gap-3" @submit="save">
      <label class="text-sm">
        {{ t("project.fields.customer") }}
        <select v-model="customerId" v-bind="customerIdAttrs" data-test="customer" class="mt-1 block w-full rounded border border-field-border p-2">
          <option value="">{{ t("project.fields.noCustomer") }}</option>
          <option v-for="customer in customers ?? []" :key="customer.id" :value="customer.id">
            {{ customer.name }}
          </option>
        </select>
        <span v-if="errors.customer_id" data-test="customer-error" class="text-[13px] text-danger">
          {{ errors.customer_id }}
        </span>
      </label>

      <label class="text-sm">
        {{ t("project.fields.name") }}
        <input v-model="name" v-bind="nameAttrs" type="text" data-test="name" class="mt-1 block w-full rounded border border-field-border p-2" />
        <span v-if="errors.name" data-test="name-error" class="text-[13px] text-danger">{{ errors.name }}</span>
      </label>

      <label class="text-sm">
        {{ t("project.fields.rate") }}
        <input v-model="rate" v-bind="rateAttrs" type="number" step="0.01" min="0" data-test="rate" class="mt-1 block w-full rounded border border-field-border p-2" />
      </label>

      <label class="text-sm">
        {{ t("project.fields.budget") }}
        <input v-model="budget" v-bind="budgetAttrs" type="number" step="0.01" min="0" data-test="budget" class="mt-1 block w-full rounded border border-field-border p-2" />
      </label>

      <label class="text-sm">
        {{ t("project.fields.budgetHours") }}
        <input v-model="budgetHours" v-bind="budgetHoursAttrs" type="number" step="0.01" min="0" data-test="budget-hours" class="mt-1 block w-full rounded border border-field-border p-2" />
      </label>

      <label class="flex items-center gap-2 text-sm">
        <input v-model="budgetOnDashboard" v-bind="budgetOnDashboardAttrs" type="checkbox" data-test="budget-on-dashboard" class="h-[18px] w-[18px] rounded border border-control-border accent-brand" />
        {{ t("project.fields.budgetOnDashboard") }}
      </label>

      <label class="text-sm">
        {{ t("project.fields.roundUp") }}
        <select v-model="roundUp" v-bind="roundUpAttrs" data-test="round-up" class="mt-1 block w-full rounded border border-field-border p-2">
          <option v-for="option in roundUpOptions" :key="option" :value="String(option)">
            {{ t(`project.roundUp.${option}`) }}
          </option>
        </select>
      </label>

      <label class="text-sm">
        {{ t("project.fields.startDate") }}
        <input v-model="startDate" v-bind="startDateAttrs" type="date" data-test="start-date" class="mt-1 block w-full rounded border border-field-border p-2" />
      </label>

      <label class="text-sm">
        {{ t("project.fields.endDate") }}
        <input v-model="endDate" v-bind="endDateAttrs" type="date" data-test="end-date" class="mt-1 block w-full rounded border border-field-border p-2" />
      </label>

      <label class="text-sm">
        {{ t("project.fields.invoiceAddition") }}
        <textarea v-model="invoiceAddition" v-bind="invoiceAdditionAttrs" rows="4" data-test="invoice-addition" class="mt-1 block w-full rounded border border-field-border p-2"></textarea>
      </label>

      <fieldset class="mt-2 border-t border-rule pt-3">
        <legend class="text-sm font-semibold">{{ t("project.tasks") }}</legend>

        <div class="flex flex-col gap-2" data-test="tasks">
          <div v-for="{ task, index } in visibleTasks" :key="task.id ?? `new-${index}`" class="flex items-center gap-2">
            <input
              v-model="task.name"
              type="text"
              :placeholder="t('project.fields.taskName')"
              :data-test="`task-name-${index}`"
              class="grow rounded border border-field-border p-2 text-sm"
            />
            <label class="flex items-center gap-1 text-sm">
              <input v-model="task.billable" type="checkbox" :data-test="`task-billable-${index}`" class="h-[18px] w-[18px] rounded border border-control-border accent-brand" />
              {{ t("project.fields.billable") }}
            </label>
            <button type="button" class="text-sm text-danger underline" :data-test="`task-remove-${index}`" @click="removeTask(index)">
              {{ t("project.removeTask") }}
            </button>
          </div>
        </div>

        <button type="button" class="mt-2 rounded border border-field-border px-3 py-1 text-sm" data-test="add-task" @click="addTask">
          {{ t("project.addTask") }}
        </button>
      </fieldset>

      <button
        type="submit"
        class="mt-4 self-start rounded-md border border-brand-border bg-brand px-4 py-2 text-white hover:bg-brand-hover"
        data-test="submit"
      >
        {{ t("project.save") }}
      </button>
    </form>
  </div>
</template>

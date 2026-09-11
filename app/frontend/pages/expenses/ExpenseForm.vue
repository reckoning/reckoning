<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import {
  useExpense,
  useAfaTypes,
  useCreateExpense,
  useUpdateExpense,
  useDestroyExpense,
  useUpdateExpenseReceipt,
  useDestroyExpenseReceipt,
} from "@/services/api/services/expenses/expenses"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import PdfViewer from "@/components/PdfViewer.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiInputGroup from "@/components/ui/UiInputGroup.vue"

// The types and intervals the select offers, in the order
// `Expense::VALID_TYPES` and `Expense.intervals` have them.
const TYPES = [
  "gwg",
  "afa",
  "licenses",
  "telecommunication",
  "training",
  "business_expenses",
  "work_related_deductions",
  "home_office",
  "current",
  "misc",
  "travel_costs",
  "non_cash_contribution",
  "business_insurances",
  "insurances",
] as const

const INTERVALS = ["once", "weekly", "monthly", "quarterly", "yearly"] as const

// What `to_prefill_params` carried into a copy of an expense.
const PREFILL = [
  "expense_type",
  "afa_type_id",
  "description",
  "seller",
  "date",
  "value",
  "private_use_percent",
  "vat_percent",
  "interval",
  "started_at",
  "ended_at",
] as const

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()

const id = computed(() => (route.params.id ? String(route.params.id) : undefined))
const editing = computed(() => id.value !== undefined)

// Both paths render this component, so the router hands the same instance
// from an edit to a new form — the copy button does exactly that. The query
// therefore follows the route rather than reading it once, or the copy would
// still be showing the expense it came from, receipt and all.
const { data: expense, isPending, refetch } = useExpense(
  computed(() => id.value ?? ""),
  { query: { enabled: computed(() => editing.value) } },
)
const { data: afaTypes } = useAfaTypes()
const { mutateAsync: create } = useCreateExpense()
const { mutateAsync: update } = useUpdateExpense()
const { mutateAsync: destroy } = useDestroyExpense()
const { mutateAsync: uploadReceipt } = useUpdateExpenseReceipt()
const { mutateAsync: removeReceipt } = useDestroyExpenseReceipt()

const loading = computed(() => editing.value && isPending.value)

// Deliberately not a `z.union`: `@vee-validate/zod` reads a union's issues
// through a field this zod version does not set, and throws out of the
// submit handler instead of reporting the error.
//
// A blank percentage is the zero the column defaults to; a blank amount is
// not, because an expense worth nothing is one nobody meant.
const percent = z
  .any()
  .transform((raw) => (raw === "" || raw === undefined || raw === null ? 0 : Number(raw)))
  .refine((entered) => Number.isFinite(entered) && entered >= 0 && entered <= 100, {
    message: "percent",
  })

const amount = z
  .any()
  .refine(
    (raw) => raw !== "" && raw !== undefined && raw !== null && Number.isFinite(Number(raw)),
    { message: "required" },
  )
  .transform(String)

const schema = toTypedSchema(
  z
    .object({
      expense_type: z.string().min(1),
      afa_type_id: z.string().optional(),
      interval: z.string().min(1),
      date: z.string().optional(),
      started_at: z.string().optional(),
      ended_at: z.string().optional(),
      description: z.string().min(1),
      seller: z.string().min(1),
      value: amount,
      private_use_percent: percent,
      vat_percent: percent,
    })
    // The model's own conditions, so the form says what it wants before the
    // endpoint does: a one-off is dated, anything on an interval starts
    // somewhere, an AfA expense has a class to write off against, and an
    // interval that ends does so after it began.
    .refine((values) => values.interval !== "once" || Boolean(values.date), {
      path: ["date"],
      message: "required",
    })
    .refine((values) => values.interval === "once" || Boolean(values.started_at), {
      path: ["started_at"],
      message: "required",
    })
    .refine((values) => values.expense_type !== "afa" || Boolean(values.afa_type_id), {
      path: ["afa_type_id"],
      message: "required",
    })
    .refine(
      (values) =>
        !values.started_at || !values.ended_at || values.ended_at >= values.started_at,
      { path: ["ended_at"], message: "after" },
    ),
)

// `new_expense_path(expense.to_prefill_params)`: the copy button on the edit
// screen opens a new form with everything filled in but nothing saved.
const prefill = computed(() => {
  const values: Record<string, string> = {}

  for (const field of PREFILL) {
    const raw = route.query[field]
    if (typeof raw === "string" && raw !== "") values[field] = raw
  }

  return values
})

const { defineField, handleSubmit, errors, setValues, resetForm, values } = useForm({
  validationSchema: schema,
  initialValues: {
    interval: "once",
    private_use_percent: 0,
    vat_percent: 0,
    ...prefill.value,
  },
})

const [expenseType, expenseTypeAttrs] = defineField("expense_type")
const [afaTypeId, afaTypeIdAttrs] = defineField("afa_type_id")
const [interval, intervalAttrs] = defineField("interval")
const [date, dateAttrs] = defineField("date")
const [startedAt, startedAtAttrs] = defineField("started_at")
const [endedAt, endedAtAttrs] = defineField("ended_at")
const [description, descriptionAttrs] = defineField("description")
const [seller, sellerAttrs] = defineField("seller")
const [value, valueAttrs] = defineField("value")
const [privateUsePercent, privateUsePercentAttrs] = defineField("private_use_percent")
const [vatPercent, vatPercentAttrs] = defineField("vat_percent")

// `expense-interval#toggle`: a one-off has a date, everything else a span.
const recurring = computed(() => values.interval !== "once")
const depreciating = computed(() => values.expense_type === "afa")

// Only the first answer for a given expense fills the form: vue-query
// refetches, and re-running this would throw away what has been typed since.
const filledFrom = ref<string | undefined>()

watch(
  expense,
  (loaded) => {
    if (!loaded || filledFrom.value === loaded.id) return

    filledFrom.value = loaded.id

    setValues({
      expense_type: loaded.expenseType,
      afa_type_id: loaded.afaTypeId ?? undefined,
      interval: loaded.interval ?? "once",
      date: loaded.date ?? "",
      started_at: loaded.startedAt ?? "",
      ended_at: loaded.endedAt ?? "",
      description: loaded.description ?? "",
      seller: loaded.seller ?? "",
      value: String(loaded.value ?? ""),
      private_use_percent: loaded.privateUsePercent ?? 0,
      vat_percent: loaded.vatPercent ?? 0,
    })
  },
  { immediate: true },
)

// A route change through the same instance starts the form over: the copy
// button goes from an edit to a new form, and what was filled in belongs to
// the expense that was left behind.
watch(id, (current, previous) => {
  if (current === previous) return

  filledFrom.value = undefined

  if (!current) {
    // A new form starts blank; an edit reached from one does not, because
    // that is where a refused receipt is waiting to be sent again.
    picked.value = undefined

    resetForm({
      values: {
        interval: "once",
        private_use_percent: 0,
        vat_percent: 0,
        ...prefill.value,
      },
    })
  }
})

const busy = ref(false)

// The file is picked before the expense exists, so it waits here and goes up
// on its own request once there is something to attach it to.
const picked = ref<File | undefined>()

function pick(event: Event): void {
  picked.value = (event.target as HTMLInputElement).files?.[0] ?? undefined
}

// Answers whether the file made it, because a refused one keeps the form
// open: it is still picked, and leaving would make the user find the expense
// again to try the same file.
async function attachPicked(expenseId: string): Promise<boolean> {
  if (!picked.value) return true

  try {
    await uploadReceipt({ id: expenseId, data: { receipt: picked.value } })
    picked.value = undefined

    return true
  } catch {
    toasts.push("error", t("expenseForm.receiptFailed"))

    return false
  }
}

const save = handleSubmit(async (submitted) => {
  busy.value = true

  const data = {
    ...submitted,
    // The columns are dates, and the fields they are not asking for stay
    // empty rather than carrying whatever was typed before the interval
    // changed.
    date: submitted.interval === "once" ? submitted.date || null : null,
    started_at: submitted.interval === "once" ? null : submitted.started_at || null,
    ended_at: submitted.interval === "once" ? null : submitted.ended_at || null,
    afa_type_id: submitted.expense_type === "afa" ? submitted.afa_type_id : null,
  }

  try {
    const wasEditing = editing.value
    const saved = wasEditing
      ? await update({ id: id.value as string, data })
      : await create({ data })

    toasts.push("success", wasEditing ? t("expenseForm.saved") : t("expenseForm.created"))

    // The expense is saved either way; a receipt that was refused keeps the
    // form open on it, so the same file can go up again.
    if (!(await attachPicked(saved.id))) {
      if (!wasEditing) await router.push({ name: "expense-edit", params: { id: saved.id }, query: listQuery.value })

      return
    }

    await router.push({ name: "expenses", query: listQuery.value })
  } catch {
    toasts.push("error", t("expenseForm.saveFailed"))
  } finally {
    busy.value = false
  }
})

async function removeExpense(): Promise<void> {
  if (!id.value) return
  if (!(await confirmDialog(t("expenseForm.confirmDelete")))) return

  try {
    await destroy({ id: id.value })
    toasts.push("success", t("expenseForm.deleted"))
    await router.push({ name: "expenses", query: listQuery.value })
  } catch {
    toasts.push("error", t("expenseForm.deleteFailed"))
  }
}

async function detachReceipt(): Promise<void> {
  if (!id.value) return
  if (!(await confirmDialog(t("expenseForm.confirmRemoveReceipt")))) return

  try {
    await removeReceipt({ id: id.value })
    await refetch()
    toasts.push("success", t("expenseForm.receiptRemoved"))
  } catch {
    toasts.push("error", t("expenseForm.receiptFailed"))
  }
}

// The filters the list was showing when it sent us here, so cancelling and
// saving both land back on it — the query is the list's state.
const listQuery = computed(() => {
  const query: Record<string, string> = {}

  for (const key of ["year", "quarter", "month", "type", "query", "page"]) {
    const raw = route.query[key]
    if (typeof raw === "string" && raw !== "") query[key] = raw
  }

  return query
})

// A copy carries everything the record has, the way `to_prefill_params` did,
// and the filters along with it.
const copyQuery = computed(() => {
  const loaded = expense.value
  if (!loaded) return listQuery.value

  const query: Record<string, string> = { ...listQuery.value }
  const fields: Record<string, unknown> = {
    expense_type: loaded.expenseType,
    afa_type_id: loaded.afaTypeId,
    description: loaded.description,
    seller: loaded.seller,
    date: loaded.date,
    value: loaded.value,
    private_use_percent: loaded.privateUsePercent,
    vat_percent: loaded.vatPercent,
    interval: loaded.interval,
    started_at: loaded.startedAt,
    ended_at: loaded.endedAt,
  }

  for (const [key, raw] of Object.entries(fields)) {
    if (raw !== null && raw !== undefined && raw !== "") query[key] = String(raw)
  }

  return query
})

const receipt = computed(() => expense.value?.receipt)

const money = computed(
  () => new Intl.NumberFormat(locale.value, { style: "currency", currency: "EUR" }),
)

// What the expense actually deducts, which the list prints and the form can
// show while the numbers are being typed.
const deductible = computed(() => {
  const amount = Number(values.value ?? 0)
  const privateShare = Number(values.private_use_percent ?? 0)

  if (!Number.isFinite(amount)) return 0

  return (amount * (100 - privateShare)) / 100
})

const FIELD = "bs-input"
</script>

<template>
  <div id="expense">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="expense-title">
        {{ editing ? t("expenseForm.editTitle") : t("expenseForm.newTitle") }}
      </h1>

      <div class="bs-btn-group max-md:w-full">
        <RouterLink :to="{ name: 'expenses', query: listQuery }" data-test="back">
          <UiButton as="span">{{ t("expenseForm.back") }}</UiButton>
        </RouterLink>
        <!-- Not while the record is still on its way: `copyQuery` has nothing
             to copy yet, so the link would open an empty form that looks like
             a copy. -->
        <template v-if="editing && expense">
          <RouterLink :to="{ name: 'expense-new', query: copyQuery }" data-test="copy">
            <UiButton as="span" variant="warning">
              <i class="fa fa-copy"></i>
              {{ t("expenseForm.copy") }}
            </UiButton>
          </RouterLink>
          <UiButton variant="danger" type="button" data-test="delete" @click="removeExpense">
            <i class="fa fa-trash"></i>
            {{ t("expenseForm.delete") }}
          </UiButton>
        </template>
      </div>
    </div>

    <p v-if="loading" class="mt-4" data-test="loading">{{ t("expenseForm.loading") }}</p>

    <form v-else class="mt-4 max-w-3xl" @submit="save">
      <div class="flex flex-wrap gap-4">
        <label class="mb-4 block grow">
          <span class="mb-1 inline-block font-bold">{{ t("expenses.columns.type") }}</span>
          <select
            v-model="expenseType"
            v-bind="expenseTypeAttrs"
            :class="FIELD"
            data-test="expense-type"
          >
            <option value="">{{ t("expenseForm.pickType") }}</option>
            <option v-for="type in TYPES" :key="type" :value="type">
              {{ t(`expenses.types.${type}`) }}
            </option>
          </select>
          <span v-if="errors.expense_type" class="mt-1 block text-danger-text" data-test="expense-type-error">
            {{ t("expenseForm.required") }}
          </span>
        </label>

        <!-- Only an AfA expense is written off, so only it names a class. -->
        <label v-if="depreciating" class="mb-4 block grow">
          <span class="mb-1 inline-block font-bold">{{ t("expenseForm.fields.afaType") }}</span>
          <select v-model="afaTypeId" v-bind="afaTypeIdAttrs" :class="FIELD" data-test="afa-type">
            <option value="">{{ t("expenseForm.pickAfaType") }}</option>
            <option v-for="afaType in afaTypes ?? []" :key="afaType.id" :value="afaType.id">
              {{ afaType.name }}
            </option>
          </select>
          <span v-if="errors.afa_type_id" class="mt-1 block text-danger-text" data-test="afa-type-error">
            {{ t("expenseForm.required") }}
          </span>
        </label>
      </div>

      <div class="flex flex-wrap gap-4">
        <label class="mb-4 block grow">
          <span class="mb-1 inline-block font-bold">{{ t("expenseForm.fields.interval") }}</span>
          <select v-model="interval" v-bind="intervalAttrs" :class="FIELD" data-test="interval">
            <option v-for="entry in INTERVALS" :key="entry" :value="entry">
              {{ t(`expenses.intervals.${entry}`) }}
            </option>
          </select>
        </label>

        <label v-if="!recurring" class="mb-4 block grow" data-test="date-field">
          <span class="mb-1 inline-block font-bold">{{ t("expenses.columns.date") }}</span>
          <input v-model="date" v-bind="dateAttrs" type="date" :class="FIELD" data-test="date" />
          <span v-if="errors.date" class="mt-1 block text-danger-text" data-test="date-error">
            {{ t("expenseForm.required") }}
          </span>
        </label>

        <template v-else>
          <label class="mb-4 block grow" data-test="started-at-field">
            <span class="mb-1 inline-block font-bold">{{ t("expenseForm.fields.startedAt") }}</span>
            <input
              v-model="startedAt"
              v-bind="startedAtAttrs"
              type="date"
              :class="FIELD"
              data-test="started-at"
            />
            <span v-if="errors.started_at" class="mt-1 block text-danger-text" data-test="started-at-error">
              {{ t("expenseForm.required") }}
            </span>
          </label>

          <label class="mb-4 block grow">
            <span class="mb-1 inline-block font-bold">{{ t("expenseForm.fields.endedAt") }}</span>
            <input
              v-model="endedAt"
              v-bind="endedAtAttrs"
              type="date"
              :class="FIELD"
              data-test="ended-at"
            />
            <span v-if="errors.ended_at" class="mt-1 block text-danger-text" data-test="ended-at-error">
              {{ t("expenseForm.endedBeforeStarted") }}
            </span>
          </label>
        </template>
      </div>

      <div class="flex flex-wrap gap-4">
        <label class="mb-4 block grow">
          <span class="mb-1 inline-block font-bold">{{ t("expenses.columns.description") }}</span>
          <input
            v-model="description"
            v-bind="descriptionAttrs"
            type="text"
            :class="FIELD"
            data-test="description"
          />
          <span v-if="errors.description" class="mt-1 block text-danger-text" data-test="description-error">
            {{ t("expenseForm.required") }}
          </span>
        </label>

        <label class="mb-4 block grow">
          <span class="mb-1 inline-block font-bold">{{ t("expenseForm.fields.seller") }}</span>
          <input v-model="seller" v-bind="sellerAttrs" type="text" :class="FIELD" data-test="seller" />
          <span v-if="errors.seller" class="mt-1 block text-danger-text" data-test="seller-error">
            {{ t("expenseForm.required") }}
          </span>
        </label>
      </div>

      <div class="flex flex-wrap items-start gap-4">
        <label class="mb-4 block grow">
          <span class="mb-1 inline-block font-bold">{{ t("expenses.columns.value") }}</span>
          <input
            v-model="value"
            v-bind="valueAttrs"
            type="number"
            step="0.01"
            :class="FIELD"
            data-test="value"
          />
          <span v-if="errors.value" class="mt-1 block text-danger-text" data-test="value-error">
            {{ t("expenseForm.required") }}
          </span>
        </label>

        <label class="mb-4 block">
          <span class="mb-1 inline-block font-bold">{{ t("expenses.privateUse") }}</span>
          <UiInputGroup addon-after="%">
            <input
              v-model="privateUsePercent"
              v-bind="privateUsePercentAttrs"
              type="number"
              min="0"
              max="100"
              :class="[FIELD, 'text-right']"
              data-test="private-use-percent"
            />
          </UiInputGroup>
        </label>

        <label class="mb-4 block">
          <span class="mb-1 inline-block font-bold">{{ t("expenses.columns.vat") }}</span>
          <UiInputGroup addon-after="%">
            <input
              v-model="vatPercent"
              v-bind="vatPercentAttrs"
              type="number"
              min="0"
              max="100"
              :class="[FIELD, 'text-right']"
              data-test="vat-percent"
            />
          </UiInputGroup>
        </label>
      </div>

      <!-- What the expense deducts is not what it cost, and the difference
           is the private share being typed right above. -->
      <p v-if="!depreciating" class="mb-4 text-muted" data-test="deductible">
        {{ t("expenseForm.deductible", { amount: money.format(deductible) }) }}
      </p>

      <div class="mb-4">
        <span class="mb-1 inline-block font-bold">{{ t("expenses.columns.receipt") }}</span>

        <div v-if="receipt" class="mb-2" data-test="receipt">
          <a :href="receipt.url" target="_blank" data-test="receipt-link">{{ receipt.filename }}</a>
          <UiButton
            type="button"
            variant="danger"
            size="small"
            class="ml-2"
            data-test="remove-receipt"
            @click="detachReceipt"
          >
            <i class="fa fa-trash"></i>
            {{ t("expenseForm.removeReceipt") }}
          </UiButton>

          <PdfViewer
            v-if="receipt.contentType === 'application/pdf'"
            :src="receipt.url"
            class="mt-2"
            data-test="receipt-preview"
          />
          <img
            v-else
            :src="receipt.url"
            :alt="receipt.filename"
            class="mt-2 max-w-sm"
            data-test="receipt-image"
          />
        </div>

        <p v-else class="mb-2 text-muted" data-test="receipt-missing">
          {{ t("expenseForm.receiptMissing") }}
        </p>

        <input
          type="file"
          accept="application/pdf,image/jpeg,image/png"
          :class="FIELD"
          data-test="receipt-file"
          @change="pick"
        />
      </div>

      <UiFormActions
        :save-label="t('expenseForm.save')"
        :cancel-label="t('expenseForm.cancel')"
        :busy="busy"
        @cancel="router.push({ name: 'expenses', query: listQuery })"
      />
    </form>
  </div>
</template>

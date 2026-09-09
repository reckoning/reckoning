<script setup lang="ts">
import { computed, ref } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import {
  useExpenseImportColumns,
  usePreviewExpenseImport,
  useCreateExpenseImport,
} from "@/services/api/services/expense-imports/expense-imports"
import type { ExpenseImportRow } from "@/services/api/models"
import { useToastsStore } from "@/stores/toasts"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormGroup from "@/components/ui/UiFormGroup.vue"
import UiInput from "@/components/ui/UiInput.vue"
import UiInputGroup from "@/components/ui/UiInputGroup.vue"

// The types and intervals the selects offer, in the order
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

// A parsed row, plus whether it is to be imported. Everything the user can
// change is edited in place; the rest travels back untouched.
interface Row extends ExpenseImportRow {
  include: boolean
}

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()

const money = computed(
  () => new Intl.NumberFormat(locale.value, { style: "currency", currency: "EUR" }),
)
const dates = computed(() => new Intl.DateTimeFormat(locale.value, { timeZone: "UTC" }))

const { data: columns } = useExpenseImportColumns()
const { mutateAsync: preview } = usePreviewExpenseImport()
const { mutateAsync: create } = useCreateExpenseImport()

const file = ref<File | null>(null)
const expenseType = ref<string>("current")
const interval = ref<string>("once")
const vatPercent = ref<string>("19")
const privateUsePercent = ref<string>("0")
const skipCredits = ref(true)

const rows = ref<Row[] | null>(null)
const busy = ref(false)
const errors = ref<string[]>([])

// Where the list was when the import started, so the way back — and the way
// out at the end — lands on the same filtered page.
const listQuery = computed(() => {
  const query: Record<string, string> = {}

  for (const key of ["year", "quarter", "month", "type", "query", "page"]) {
    const raw = route.query[key]
    if (typeof raw === "string" && raw !== "") query[key] = raw
  }

  return query
})

const selected = computed(() => (rows.value ?? []).filter((row) => row.include))

function onFile(event: Event): void {
  const input = event.target as HTMLInputElement
  file.value = input.files?.[0] ?? null
}

function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : "—"
}

async function onPreview(): Promise<void> {
  if (!file.value || busy.value) return

  busy.value = true
  errors.value = []

  try {
    const parsed = await preview({
      data: {
        file: file.value,
        expense_type: expenseType.value,
        interval: interval.value,
        vat_percent: vatPercent.value,
        private_use_percent: privateUsePercent.value,
        skip_credits: skipCredits.value,
      },
    })

    rows.value = (parsed.rows ?? []).map((row) => ({ ...row, include: true }))
  } catch {
    errors.value = [t("expenseImport.parseFailed")]
  } finally {
    busy.value = false
  }
}

async function onImport(): Promise<void> {
  if (busy.value) return

  if (selected.value.length === 0) {
    errors.value = [t("expenseImport.noRows")]
    return
  }

  busy.value = true
  errors.value = []

  try {
    const result = await create({
      data: {
        rows: selected.value.map((row) => ({
          include: true,
          id: row.id,
          date: row.date,
          started_at: row.startedAt,
          ended_at: row.endedAt,
          value: row.value,
          vat_percent: row.vatPercent,
          private_use_percent: row.privateUsePercent,
          interval: row.interval,
          afa_type_id: row.afaTypeId,
          seller: row.seller,
          description: row.description,
          expense_type: row.expenseType,
        })),
      },
    })

    toasts.push("success", t("expenseImport.imported", { count: result.count ?? selected.value.length }, result.count ?? selected.value.length))
    await router.push({ name: "expenses", query: listQuery.value })
  } catch (error: unknown) {
    // The rows the server refused come back as messages naming their line.
    const data = (error as {response?: {data?: {errors?: Record<string, string[]>; message?: string}}})
      .response?.data

    const messages = Object.values(data?.errors ?? {}).flat()

    errors.value = messages.length > 0 ? messages : [data?.message ?? t("expenseImport.importFailed")]
  } finally {
    busy.value = false
  }
}

function back(): void {
  if (rows.value) {
    rows.value = null
    errors.value = []
    return
  }

  router.push({ name: "expenses", query: listQuery.value })
}
</script>

<template>
  <div id="expense-import">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="import-title">{{ t("expenseImport.title") }}</h1>

      <UiButton data-test="back" @click="back">{{ t("expenseImport.back") }}</UiButton>
    </div>

    <UiAlert v-if="errors.length > 0" variant="danger" data-test="import-errors">
      <ul>
        <li v-for="message in errors" :key="message">{{ message }}</li>
      </ul>
    </UiAlert>

    <!-- Step one: the file, and the defaults every parsed row starts with. -->
    <form v-if="!rows" novalidate @submit.prevent="onPreview">
      <p>{{ t("expenseImport.hintBank") }}</p>
      <p class="mt-2">{{ t("expenseImport.hintColumns") }}</p>

      <ul class="my-4 list-disc pl-5" data-test="import-columns">
        <li v-for="column in columns?.columns ?? []" :key="column.name">
          <strong>{{ column.name }}</strong>
          - {{ column.type }}
        </li>
      </ul>

      <p>{{ t("expenseImport.hintId") }}</p>

      <UiFormGroup :label="t('expenseImport.fields.file')" class="mt-5">
        <input
          type="file"
          accept=".csv,text/csv"
          class="block w-full"
          data-test="file"
          @change="onFile"
        />
      </UiFormGroup>

      <fieldset class="mt-4">
        <legend class="mb-4 w-full border-b border-rule pb-1 text-xl">
          {{ t("expenseImport.defaultsTitle") }}
        </legend>

        <div class="grid grid-cols-12 gap-4">
          <div class="col-span-12 md:col-span-4">
            <UiFormGroup :label="t('expenseImport.fields.expenseType')">
              <UiInput v-model="expenseType" as="select" data-test="expense-type">
                <option v-for="type in TYPES" :key="type" :value="type">
                  {{ t(`expenses.types.${type}`) }}
                </option>
              </UiInput>
            </UiFormGroup>
          </div>

          <div class="col-span-12 md:col-span-4">
            <UiFormGroup :label="t('expenseImport.fields.interval')">
              <UiInput v-model="interval" as="select" data-test="interval">
                <option v-for="entry in INTERVALS" :key="entry" :value="entry">
                  {{ t(`expenses.intervals.${entry}`) }}
                </option>
              </UiInput>
            </UiFormGroup>
          </div>
        </div>

        <div class="grid grid-cols-12 gap-4">
          <div class="col-span-12 md:col-span-4">
            <UiFormGroup :label="t('expenseImport.fields.vatPercent')">
              <UiInputGroup addon-after="%">
                <UiInput
                  v-model="vatPercent"
                  type="number"
                  min="0"
                  max="100"
                  class="text-right"
                  data-test="vat-percent"
                />
              </UiInputGroup>
            </UiFormGroup>
          </div>

          <div class="col-span-12 md:col-span-4">
            <UiFormGroup :label="t('expenseImport.fields.privateUsePercent')">
              <UiInputGroup addon-after="%">
                <UiInput
                  v-model="privateUsePercent"
                  type="number"
                  min="0"
                  max="100"
                  class="text-right"
                  data-test="private-use-percent"
                />
              </UiInputGroup>
            </UiFormGroup>
          </div>
        </div>

        <label class="mb-4 flex cursor-pointer items-center gap-2">
          <input v-model="skipCredits" type="checkbox" data-test="skip-credits" />
          <span>{{ t("expenseImport.fields.skipCredits") }}</span>
        </label>
      </fieldset>

      <hr class="my-5 border-t border-rule" />

      <div class="flex flex-wrap gap-2 max-md:flex-col">
        <UiButton
          variant="primary"
          size="large"
          type="submit"
          :disabled="!file || busy"
          data-test="continue"
        >
          {{ busy ? t("expenseImport.parsing") : t("expenseImport.continue") }}
        </UiButton>

        <RouterLink v-slot="{ href, navigate }" :to="{ name: 'expenses', query: listQuery }" custom>
          <UiButton as="a" :href="href" data-test="cancel" @click="navigate">
            {{ t("expenseImport.cancel") }}
          </UiButton>
        </RouterLink>
      </div>
    </form>

    <!-- Step two: what came out of the file, editable before it is saved. -->
    <form v-else novalidate @submit.prevent="onImport">
      <p>{{ t("expenseImport.previewHint") }}</p>

      <div class="mt-4 overflow-x-auto">
        <table class="w-full" data-test="preview-rows">
          <thead>
            <tr class="border-b-2 border-rule-strong text-left">
              <th class="p-2">{{ t("expenseImport.columns.include") }}</th>
              <th class="p-2">{{ t("expenseImport.columns.date") }}</th>
              <th class="p-2 text-right">{{ t("expenseImport.columns.value") }}</th>
              <th class="p-2">{{ t("expenseImport.columns.seller") }}</th>
              <th class="p-2">{{ t("expenseImport.columns.description") }}</th>
              <th class="p-2">{{ t("expenseImport.columns.expenseType") }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(row, index) in rows"
              :key="index"
              class="border-b border-rule odd:bg-surface-stripe"
              :data-test="`row-${index}`"
            >
              <td class="p-2">
                <input
                  v-model="row.include"
                  type="checkbox"
                  :aria-label="t('expenseImport.columns.include')"
                  :data-test="`include-${index}`"
                />
              </td>
              <td class="p-2 whitespace-nowrap">{{ formatDate(row.date) }}</td>
              <td class="p-2 text-right whitespace-nowrap">
                {{ money.format(Number(row.value ?? 0)) }}
              </td>
              <td class="p-2">
                <UiInput v-model="row.seller" :data-test="`seller-${index}`" />
              </td>
              <td class="p-2">
                <UiInput v-model="row.description" :data-test="`description-${index}`" />
              </td>
              <td class="p-2">
                <UiInput v-model="row.expenseType" as="select" :data-test="`type-${index}`">
                  <option v-for="type in TYPES" :key="type" :value="type">
                    {{ t(`expenses.types.${type}`) }}
                  </option>
                </UiInput>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <hr class="my-5 border-t border-rule" />

      <div class="flex flex-wrap gap-2 max-md:flex-col">
        <UiButton
          variant="primary"
          size="large"
          type="submit"
          :disabled="busy"
          data-test="import"
        >
          {{
            busy
              ? t("expenseImport.importing")
              : t("expenseImport.submit", { count: selected.length }, selected.length)
          }}
        </UiButton>

        <RouterLink v-slot="{ href, navigate }" :to="{ name: 'expenses', query: listQuery }" custom>
          <UiButton as="a" :href="href" data-test="cancel" @click="navigate">
            {{ t("expenseImport.cancel") }}
          </UiButton>
        </RouterLink>
      </div>
    </form>
  </div>
</template>

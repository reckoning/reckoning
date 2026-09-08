<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter } from "vue-router"
import { useI18n } from "vue-i18n"
import { useQueryClient } from "@tanstack/vue-query"
import {
  useExpenses,
  useExpenseSummary,
  useBulkUpdateExpenses,
  useBulkDestroyExpenses,
  getExpensesQueryKey,
  getExpenseSummaryQueryKey,
} from "@/services/api/services/expenses/expenses"
import type { Expense } from "@/services/api/models"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import UiButton from "@/components/ui/UiButton.vue"
import UiFilter from "@/components/ui/UiFilter.vue"
import UiInput from "@/components/ui/UiInput.vue"
import UiInputGroup from "@/components/ui/UiInputGroup.vue"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiPagination from "@/components/ui/UiPagination.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

// Every type an expense can be filed under, in the order
// `Expense::VALID_TYPES` has them.
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

const FILTERS = ["year", "quarter", "month", "type", "query"] as const

type Filter = (typeof FILTERS)[number]

// The server-rendered list paged at forty.
const PER_PAGE = 40

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()
const queryClient = useQueryClient()

function queryValue(key: string): string {
  const raw = route.query[key]

  return typeof raw === "string" ? raw : ""
}

const page = computed(() => Math.max(1, Number(queryValue("page")) || 1))

// The query is the state, so a filtered page is a link someone can send.
const filterParams = computed(() => {
  const query: Record<string, string> = {}

  for (const filter of FILTERS) {
    const value = queryValue(filter)
    if (value) query[filter] = value
  }

  return query
})

const params = computed(() => ({ ...filterParams.value, page: page.value, perPage: PER_PAGE }))

const { data: expenses, isPending, isError } = useExpenses(params)
// Same filters, minus paging: the total under a filtered table has to belong
// to that table.
const { data: summary } = useExpenseSummary(filterParams)

const { mutateAsync: bulkUpdate } = useBulkUpdateExpenses()
const { mutateAsync: bulkDestroy } = useBulkDestroyExpenses()

function go(changes: Record<string, string | number | undefined>): void {
  const query: Record<string, string> = {}

  for (const [key, value] of Object.entries({ ...route.query, ...changes })) {
    if (typeof value === "string" && value !== "") query[key] = value
    if (typeof value === "number") query[key] = String(value)
  }

  router.push({ query })
}

function setFilter(filter: Filter, value: string): void {
  go({ [filter]: value || undefined, page: undefined })
}

const search = ref(queryValue("query"))

// The url is the state, and it also moves on its own — the back button, a
// link someone opened. The field follows it rather than keeping whatever was
// typed into it before.
watch(
  () => queryValue("query"),
  (query) => (search.value = query),
)

function submitSearch(): void {
  setFilter("query", search.value.trim())
}

function resetSearch(): void {
  search.value = ""
  setFilter("query", "")
}

const money = computed(
  () => new Intl.NumberFormat(locale.value, { style: "currency", currency: "EUR" }),
)
// `I18n.l` prints the day and the month padded — 12.04.2026, not 12.4.2026.
const dates = computed(
  () =>
    new Intl.DateTimeFormat(locale.value, {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      timeZone: "UTC",
    }),
)

// `date` arrives as a bare YYYY-MM-DD, and read in local time that is the day
// before west of Greenwich — so it is read and printed in UTC.
function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

// A one-off prints its date; anything on an interval prints the interval and
// the span it runs for, the way the server-rendered row did.
function period(expense: Expense): string {
  if (expense.interval === "once") return formatDate(expense.date)

  const interval = t(`expenses.intervals.${expense.interval}`)

  return `${interval}: ${formatDate(expense.startedAt)} - ${formatDate(expense.endedAt)}`
}

const monthOptions = computed(() => {
  const format = new Intl.DateTimeFormat(locale.value, { month: "long", timeZone: "UTC" })

  return Array.from({ length: 12 }, (_, index) => ({
    value: String(index + 1),
    label: format.format(new Date(Date.UTC(2024, index, 1))),
  }))
})

const quarterOptions = [1, 2, 3, 4].map((quarter) => ({
  value: String(quarter),
  label: `Q${quarter}`,
}))

const yearOptions = computed(() =>
  (summary.value?.years ?? []).map((year) => ({ value: String(year), label: String(year) })),
)

const typeOptions = computed(() =>
  TYPES.map((type) => ({ value: type, label: t(`expenses.types.${type}`) })),
)

// The client cannot read the Link header through the generated mutator, so
// the filtered count answers it: a full last page would otherwise offer a
// next page that is empty.
const hasNextPage = computed(() => page.value * PER_PAGE < (summary.value?.count ?? 0))

// Kaminari printed nothing at all while everything fit on one page.
const paged = computed(() => page.value > 1 || hasNextPage.value)

const selected = ref<string[]>([])

// Dropped whenever the result set changes: a row ticked on page one, or
// under another filter, is not on screen any more, and the bulk bar would
// otherwise apply — or delete — what nobody can see.
watch(params, () => (selected.value = []))

function toggle(id: string, on: boolean): void {
  selected.value = on ? [...selected.value, id] : selected.value.filter((entry) => entry !== id)
}

const allSelected = computed(
  () => (expenses.value?.length ?? 0) > 0 && selected.value.length === expenses.value?.length,
)

function toggleAll(on: boolean): void {
  selected.value = on ? (expenses.value ?? []).map((expense) => expense.id) : []
}

// What the bulk bar applies. A field left empty means "leave this one
// alone", which is what its placeholder says.
const bulkType = ref("")
const bulkVat = ref("")
const bulkPrivateUse = ref("")

const bulkAttributes = computed(() => {
  const attributes: Record<string, string | number> = {}

  if (bulkType.value) attributes.expense_type = bulkType.value
  if (bulkVat.value !== "") attributes.vat_percent = Number(bulkVat.value)
  if (bulkPrivateUse.value !== "") attributes.private_use_percent = Number(bulkPrivateUse.value)

  return attributes
})

const busy = ref(false)

async function refresh(): Promise<void> {
  selected.value = []
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: getExpensesQueryKey(params.value) }),
    queryClient.invalidateQueries({ queryKey: getExpenseSummaryQueryKey(filterParams.value) }),
  ])
}

async function applyBulk(): Promise<void> {
  if (selected.value.length === 0 || Object.keys(bulkAttributes.value).length === 0) return

  busy.value = true
  try {
    const result = await bulkUpdate({
      data: { expenseIds: selected.value, ...bulkAttributes.value },
    })
    toasts.push("success", result.message ?? t("expenses.bulk.applied"))
    bulkType.value = ""
    bulkVat.value = ""
    bulkPrivateUse.value = ""
    await refresh()
  } catch {
    toasts.push("error", t("expenses.bulk.failed"))
  } finally {
    busy.value = false
  }
}

async function destroyBulk(): Promise<void> {
  if (selected.value.length === 0) return
  if (!(await confirmDialog(t("expenses.bulk.confirmDelete")))) return

  busy.value = true
  try {
    const result = await bulkDestroy({ data: { expenseIds: selected.value } })
    toasts.push("success", result.message ?? t("expenses.bulk.deleted"))
    await refresh()
  } catch {
    toasts.push("error", t("expenses.bulk.failed"))
  } finally {
    busy.value = false
  }
}

// The PDF and the CSV are rendered by the server, filters and all, so the
// buttons carry the same query across to the Rails route.
const exportQuery = computed(() => new URLSearchParams(filterParams.value).toString())

function exportPath(format: string): string {
  return `/expenses.${format}${exportQuery.value ? `?${exportQuery.value}` : ""}`
}
</script>

<template>
  <div id="expenses">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow">
        {{ t("expenses.title") }}
        <br />
        <small data-test="summary">
          <span data-test="summary-value">
            {{ t("expenses.sum", { sum: money.format(Number(summary?.value ?? 0)) }) }}
          </span>
          <br />
          <span data-test="summary-vat">
            {{ t("expenses.vatSum", { sum: money.format(Number(summary?.vat ?? 0)) }) }}
          </span>
        </small>
      </h1>

      <!-- One welded group, the way `btn-group-justified-responsive` had it.
           The form and the import are still the server-rendered screens. -->
      <div class="bs-btn-group max-md:w-full">
        <UiButton as="a" href="/expenses/new" variant="primary" data-test="new-expense">
          <i class="fa fa-plus"></i> {{ t("expenses.new") }}
        </UiButton>
        <UiButton as="a" :href="exportPath('pdf')" target="_blank" data-test="export-pdf">
          <i class="fa fa-down"></i> {{ t("expenses.exportPdf") }}
        </UiButton>
        <UiButton as="a" :href="exportPath('csv')" target="_blank" data-test="export-csv">
          <i class="fa fa-down"></i> {{ t("expenses.exportCsv") }}
        </UiButton>
        <UiButton as="a" href="/expense_imports/new" data-test="import">
          <i class="fa fa-upload"></i> {{ t("expenses.import") }}
        </UiButton>
      </div>
    </div>

    <div class="mt-4 flex flex-wrap items-start justify-between gap-y-4">
      <div class="flex flex-wrap items-start gap-1.5" data-test="filters">
        <UiFilter
          :label="t('expenses.filters.year')"
          :model-value="queryValue('year')"
          :options="yearOptions"
          :reset-title="t('expenses.filters.reset')"
          test="filter-year"
          @update:model-value="setFilter('year', $event)"
        />
        <UiFilter
          :label="t('expenses.filters.quarter')"
          :model-value="queryValue('quarter')"
          :options="quarterOptions"
          :reset-title="t('expenses.filters.reset')"
          test="filter-quarter"
          @update:model-value="setFilter('quarter', $event)"
        />
        <UiFilter
          :label="t('expenses.filters.month')"
          :model-value="queryValue('month')"
          :options="monthOptions"
          :reset-title="t('expenses.filters.reset')"
          test="filter-month"
          @update:model-value="setFilter('month', $event)"
        />
        <UiFilter
          :label="t('expenses.filters.type')"
          :model-value="queryValue('type')"
          :options="typeOptions"
          :reset-title="t('expenses.filters.reset')"
          align="right"
          test="filter-type"
          @update:model-value="setFilter('type', $event)"
        />

        <form class="max-md:w-full" data-test="search-form" @submit.prevent="submitSearch">
          <UiInputGroup>
            <UiInput
              v-model="search"
              type="search"
              :placeholder="t('expenses.filters.search')"
              data-test="search"
            />
            <template #button>
              <UiButton
                v-if="queryValue('query')"
                variant="danger"
                :title="t('expenses.filters.reset')"
                data-test="search-reset"
                @click="resetSearch"
              >
                <i class="fa fa-times"></i>
              </UiButton>
              <UiButton v-else variant="primary" type="submit" data-test="search-submit">
                <i class="fa fa-search"></i>
              </UiButton>
            </template>
          </UiInputGroup>
        </form>
      </div>

      <UiPagination
        v-if="paged"
        :page="page"
        :has-next="hasNextPage"
        :previous-label="t('expenses.previous')"
        :next-label="t('expenses.next')"
        class="max-md:w-full"
        @go="go({ page: $event })"
      />
    </div>

    <!-- The bar the server-rendered list slid out once a row was ticked. -->
    <UiPanel v-if="selected.length > 0" class="mt-4" data-test="bulk-bar">
      <template #body>
        <div class="flex flex-wrap items-end gap-3">
          <strong data-test="bulk-count">
            {{ t("expenses.bulk.selected", { count: selected.length }) }}
          </strong>

          <label class="block">
            <span class="mb-1 block">{{ t("expenses.columns.type") }}</span>
            <UiInput v-model="bulkType" as="select" data-test="bulk-type">
              <option value="">{{ t("expenses.bulk.unchanged") }}</option>
              <option v-for="option in typeOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </UiInput>
          </label>

          <label class="block">
            <span class="mb-1 block">{{ t("expenses.columns.vat") }}</span>
            <UiInputGroup addon-after="%">
              <UiInput
                v-model="bulkVat"
                type="number"
                min="0"
                max="100"
                class="text-right"
                :placeholder="t('expenses.bulk.unchanged')"
                data-test="bulk-vat"
              />
            </UiInputGroup>
          </label>

          <label class="block">
            <span class="mb-1 block">{{ t("expenses.privateUse") }}</span>
            <UiInputGroup addon-after="%">
              <UiInput
                v-model="bulkPrivateUse"
                type="number"
                min="0"
                max="100"
                class="text-right"
                :placeholder="t('expenses.bulk.unchanged')"
                data-test="bulk-private-use"
              />
            </UiInputGroup>
          </label>

          <div class="flex gap-2">
            <UiButton variant="primary" :disabled="busy" data-test="bulk-apply" @click="applyBulk">
              {{ t("expenses.bulk.apply") }}
            </UiButton>
            <UiButton variant="danger" :disabled="busy" data-test="bulk-delete" @click="destroyBulk">
              {{ t("expenses.bulk.delete") }}
            </UiButton>
          </div>
        </div>
      </template>
    </UiPanel>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("expenses.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("expenses.loadFailed") }}</p>
    <p v-else-if="expenses && expenses.length === 0" class="mt-4" data-test="empty">
      {{ t("expenses.empty") }}
    </p>

    <UiPanel v-else class="mt-4" list data-test="expenses">
      <template #heading>
        <div class="flex items-center gap-3">
          <input
            type="checkbox"
            :checked="allSelected"
            :aria-label="t('expenses.bulk.selectAll')"
            data-test="select-all"
            @change="toggleAll(($event.target as HTMLInputElement).checked)"
          />
          <div class="hidden grow grid-cols-12 gap-2 md:grid">
            <div class="col-span-2">{{ t("expenses.columns.date") }}</div>
            <div class="col-span-3">{{ t("expenses.columns.description") }}</div>
            <div class="col-span-2">{{ t("expenses.columns.type") }}</div>
            <div class="col-span-2">{{ t("expenses.columns.vat") }}</div>
            <div class="col-span-3">
              {{ t("expenses.columns.receipt") }}
              <span class="float-right">{{ t("expenses.columns.value") }}</span>
            </div>
          </div>
        </div>
      </template>

      <UiListGroup>
        <UiListGroupItem
          v-for="expense in expenses"
          :key="expense.id"
          :data-test="`expense-${expense.id}`"
        >
          <div class="flex items-start gap-3">
            <input
              type="checkbox"
              class="mt-1"
              :checked="selected.includes(expense.id)"
              :aria-label="t('expenses.bulk.selectRow')"
              :data-test="`select-${expense.id}`"
              @change="toggle(expense.id, ($event.target as HTMLInputElement).checked)"
            />

            <div class="grid grow grid-cols-12 items-center gap-x-2 gap-y-2">
              <div class="col-span-6 md:col-span-2">{{ period(expense) }}</div>

              <div class="col-span-6 md:col-span-3">
                <!-- The form is still the server-rendered one; this turns
                     into a router link when it moves over. -->
                <a
                  :href="`/expenses/${expense.id}/edit`"
                  :title="t('expenses.edit')"
                  :data-test="`edit-${expense.id}`"
                >
                  <b>{{ expense.description }}</b>
                </a>
              </div>

              <div class="col-span-6 md:col-span-2">
                {{ t(`expenses.types.${expense.expenseType}`) }}
              </div>

              <div class="col-span-6 tabular-nums md:col-span-2">
                {{ money.format(Number(expense.vatValue ?? 0)) }}
              </div>

              <div class="col-span-12 md:col-span-3">
                <i
                  v-if="expense.hasReceipt"
                  class="fa fa-file"
                  :title="t('expenses.receiptAttached')"
                  :data-test="`receipt-${expense.id}`"
                ></i>
                <i
                  v-else-if="expense.needsReceipt"
                  class="fa fa-file text-danger-text"
                  :title="t('expenses.receiptMissing')"
                  :data-test="`receipt-missing-${expense.id}`"
                ></i>
                <!-- `.expense-price`: the amount is the loudest thing in
                     the row. -->
                <span class="float-right text-[20px] font-bold tabular-nums">
                  {{ money.format(Number(expense.usableValue ?? 0)) }}
                </span>
              </div>
            </div>
          </div>
        </UiListGroupItem>
      </UiListGroup>
    </UiPanel>

    <UiPagination
      v-if="paged"
      :page="page"
      :has-next="hasNextPage"
      :previous-label="t('expenses.previous')"
      :next-label="t('expenses.next')"
      class="mt-4"
      @go="go({ page: $event })"
    />
  </div>
</template>

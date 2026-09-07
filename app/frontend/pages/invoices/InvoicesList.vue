<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useInvoices, useInvoiceSummary } from "@/services/api/services/invoices/invoices"
import { useAccount } from "@/services/api/services/account/account"

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

// The query is the state, so a filtered, sorted page is a link someone can
// send — which is what `data-turbo-action="advance"` bought the ERB list.
const FILTERS = [
  "state",
  "year",
  "quarter",
  "month",
  "paid_in_year",
  "paid_in_quarter",
  "paid_in_month",
] as const

type Filter = (typeof FILTERS)[number]

const PER_PAGE = 25

function queryValue(key: string): string {
  const raw = route.query[key]

  return typeof raw === "string" ? raw : ""
}

const page = computed(() => Math.max(1, Number(queryValue("page")) || 1))
const sort = computed(() => queryValue("sort"))
const direction = computed(() => (queryValue("direction") === "asc" ? "asc" : "desc"))

const params = computed(() => {
  const query: Record<string, string | number> = {page: page.value, perPage: PER_PAGE}

  for (const filter of FILTERS) {
    const value = queryValue(filter)
    if (value) query[filter] = value
  }

  if (sort.value) {
    query.sort = sort.value
    query.direction = direction.value
  }

  return query
})

// Same filters, minus paging: the total under a filtered table has to belong
// to that table.
const summaryParams = computed(() => {
  const query: Record<string, string> = {}

  for (const filter of FILTERS) {
    const value = queryValue(filter)
    if (value) query[filter] = value
  }

  return query
})

const { data: invoices, isPending, isError } = useInvoices(params)
const { data: summary } = useInvoiceSummary(summaryParams)
const { data: account } = useAccount()

// A demo deployment caps non-admins at two invoices, and the server bounces
// them back — to a list that does not render the flash saying why. The ERB
// screen greyed the button out, so this one does too.
const limitReached = computed(() => account.value?.invoiceLimitReached === true)

function go(changes: Record<string, string | number | undefined>): void {
  const query: Record<string, string> = {}

  for (const [key, value] of Object.entries({...route.query, ...changes})) {
    if (typeof value === "string" && value !== "") query[key] = value
    if (typeof value === "number") query[key] = String(value)
  }

  router.push({query})
}

function setFilter(filter: Filter, value: string): void {
  go({[filter]: value || undefined, page: undefined})
}

// Clicking the column you are already sorted by turns it around.
function sortBy(column: string): void {
  const flip = sort.value === column && direction.value === "desc" ? "asc" : "desc"

  go({sort: column, direction: flip, page: undefined})
}

const money = computed(
  () => new Intl.NumberFormat(locale.value, {style: "currency", currency: "EUR"}),
)
// `date` arrives as a bare YYYY-MM-DD. `new Date("2026-03-01")` is UTC
// midnight, and formatted in local time that is the 28th of February west of
// Greenwich — so the anchor is read and printed in UTC.
const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, {dateStyle: "medium", timeZone: "UTC"}),
)

function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

const monthOptions = computed(() => {
  const format = new Intl.DateTimeFormat(locale.value, {month: "long", timeZone: "UTC"})

  return Array.from({length: 12}, (_, index) => ({
    value: String(index + 1),
    label: format.format(new Date(Date.UTC(2024, index, 1))),
  }))
})

const quarterOptions = [1, 2, 3, 4].map((quarter) => ({
  value: String(quarter),
  label: `Q${quarter}`,
}))

const yearOptions = computed(() =>
  (summary.value?.years ?? []).map((year) => ({value: String(year), label: String(year)})),
)

const stateOptions = ["created", "charged", "paid"].map((state) => ({
  value: state,
  label: state,
}))

// The API pages; the client cannot read the Link header through the generated
// mutator, so a full page is taken as "there may be more".
const hasNextPage = computed(() => (invoices.value?.length ?? 0) === PER_PAGE)
</script>

<template>
  <div class="p-4">
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-[24px] font-medium">{{ t("invoices.title") }}</h1>

      <RouterLink
        v-if="!limitReached"
        :to="{ name: 'invoice-new' }"
        class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover"
        data-test="new-invoice"
      >
        {{ t("invoices.new") }}
      </RouterLink>
      <span
        v-else
        class="cursor-not-allowed rounded-md border border-field-border bg-surface-muted px-4 py-2 text-sm text-muted"
        :title="t('invoices.limitReached')"
        data-test="new-invoice-disabled"
      >
        {{ t("invoices.new") }}
      </span>
    </div>

    <div class="mb-4 flex flex-wrap gap-2" data-test="filters">
      <select
        :value="queryValue('state')"
        data-test="filter-state"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('state', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.state") }}</option>
        <option v-for="option in stateOptions" :key="option.value" :value="option.value">
          {{ t(`invoices.states.${option.value}`) }}
        </option>
      </select>

      <select
        :value="queryValue('year')"
        data-test="filter-year"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('year', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.year") }}</option>
        <option v-for="option in yearOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>

      <select
        :value="queryValue('quarter')"
        data-test="filter-quarter"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('quarter', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.quarter") }}</option>
        <option v-for="option in quarterOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>

      <select
        :value="queryValue('month')"
        data-test="filter-month"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('month', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.month") }}</option>
        <option v-for="option in monthOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>

      <select
        :value="queryValue('paid_in_year')"
        data-test="filter-paid-in-year"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('paid_in_year', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.paidInYear") }}</option>
        <option v-for="option in yearOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>

      <select
        :value="queryValue('paid_in_quarter')"
        data-test="filter-paid-in-quarter"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('paid_in_quarter', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.paidInQuarter") }}</option>
        <option v-for="option in quarterOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>

      <select
        :value="queryValue('paid_in_month')"
        data-test="filter-paid-in-month"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('paid_in_month', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("invoices.filters.paidInMonth") }}</option>
        <option v-for="option in monthOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>
    </div>

    <p v-if="isPending" data-test="loading">{{ t("invoices.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("invoices.loadFailed") }}</p>
    <p v-else-if="invoices && invoices.length === 0" data-test="empty">{{ t("invoices.empty") }}</p>

    <div v-else class="overflow-x-auto">
      <table class="w-full border-collapse text-sm" data-test="invoices">
        <thead>
          <tr class="border-b border-rule-strong text-left">
            <th v-for="column in ['ref', 'customer', 'date', 'value', 'state']" :key="column" class="px-2 py-2">
              <button type="button" class="font-semibold underline" :data-test="`sort-${column}`" @click="sortBy(column)">
                {{ t(`invoices.columns.${column}`) }}
                <span v-if="sort === column" aria-hidden="true">{{ direction === "asc" ? "↑" : "↓" }}</span>
              </button>
            </th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="invoice in invoices" :key="invoice.id" class="border-b border-rule" :data-test="`invoice-${invoice.id}`">
            <td class="px-2 py-2 tabular-nums">
              <RouterLink
                :to="{ name: 'invoice', params: { id: invoice.id } }"
                class="text-brand"
              >{{ invoice.refNumber ?? invoice.ref }}</RouterLink>
            </td>
            <td class="px-2 py-2">{{ invoice.customerName }}</td>
            <td class="px-2 py-2 tabular-nums">{{ formatDate(invoice.date) }}</td>
            <td class="px-2 py-2 text-right tabular-nums">{{ money.format(Number(invoice.value ?? 0)) }}</td>
            <td class="px-2 py-2">{{ invoice.state ? t(`invoices.states.${invoice.state}`) : "" }}</td>
          </tr>
        </tbody>

        <tfoot v-if="summary">
          <tr class="font-semibold" data-test="summary">
            <td class="px-2 py-2" colspan="3">
              {{ t("invoices.summary", { count: summary.count }) }}
            </td>
            <td class="px-2 py-2 text-right tabular-nums" data-test="summary-value">
              {{ money.format(Number(summary.value)) }}
            </td>
            <td class="px-2 py-2 text-right tabular-nums" data-test="summary-vat">
              {{ money.format(Number(summary.vat)) }}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>

    <nav class="mt-4 flex items-center gap-3" data-test="pagination">
      <button
        type="button"
        class="rounded border border-field-border px-3 py-1 text-sm disabled:opacity-50"
        :disabled="page === 1"
        data-test="prev-page"
        @click="go({ page: page - 1 })"
      >
        {{ t("invoices.previous") }}
      </button>

      <span class="text-sm text-muted" data-test="page">{{ page }}</span>

      <button
        type="button"
        class="rounded border border-field-border px-3 py-1 text-sm disabled:opacity-50"
        :disabled="!hasNextPage"
        data-test="next-page"
        @click="go({ page: page + 1 })"
      >
        {{ t("invoices.next") }}
      </button>
    </nav>
  </div>
</template>

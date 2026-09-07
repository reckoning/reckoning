<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter } from "vue-router"
import { useI18n } from "vue-i18n"
import { useOffers, useOfferSummary } from "@/services/api/services/offers/offers"

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

// The query is the state, so a filtered, sorted page is a link someone can
// send — which is what `data-turbo-action="advance"` bought the ERB list.
const FILTERS = ["state", "year"] as const

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

const { data: offers, isPending, isError } = useOffers(params)
const { data: summary } = useOfferSummary(summaryParams)

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

const yearOptions = computed(() =>
  (summary.value?.years ?? []).map((year) => ({value: String(year), label: String(year)})),
)

const STATES = ["created", "bided", "accepted", "declined", "canceled"] as const

// The API pages; the client cannot read the Link header through the generated
// mutator, so a full page is taken as "there may be more".
const hasNextPage = computed(() => (offers.value?.length ?? 0) === PER_PAGE)
</script>

<template>
  <div class="p-4">
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-[24px] font-medium">{{ t("offers.title") }}</h1>

      <a
        href="/offers/new"
        class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover"
        data-test="new-offer"
      >
        {{ t("offers.new") }}
      </a>
    </div>

    <div class="mb-4 flex flex-wrap gap-2" data-test="filters">
      <select
        :value="queryValue('state')"
        data-test="filter-state"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('state', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("offers.filters.state") }}</option>
        <option v-for="state in STATES" :key="state" :value="state">
          {{ t(`offers.states.${state}`) }}
        </option>
      </select>

      <select
        :value="queryValue('year')"
        data-test="filter-year"
        class="rounded border border-field-border p-2 text-sm"
        @change="setFilter('year', ($event.target as HTMLSelectElement).value)"
      >
        <option value="">{{ t("offers.filters.year") }}</option>
        <option v-for="option in yearOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>
    </div>

    <p v-if="isPending" data-test="loading">{{ t("offers.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("offers.loadFailed") }}</p>
    <p v-else-if="offers && offers.length === 0" data-test="empty">{{ t("offers.empty") }}</p>

    <div v-else class="overflow-x-auto">
      <table class="w-full border-collapse text-sm" data-test="offers">
        <thead>
          <tr class="border-b border-rule-strong text-left">
            <th v-for="column in ['ref', 'customer', 'date', 'value', 'state']" :key="column" class="px-2 py-2">
              <button type="button" class="font-semibold underline" :data-test="`sort-${column}`" @click="sortBy(column)">
                {{ t(`offers.columns.${column}`) }}
                <span v-if="sort === column" aria-hidden="true">{{ direction === "asc" ? "↑" : "↓" }}</span>
              </button>
            </th>
            <th class="px-2 py-2">{{ t("offers.columns.project") }}</th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="offer in offers" :key="offer.id" class="border-b border-rule" :data-test="`offer-${offer.id}`">
            <td class="px-2 py-2 tabular-nums">
              <a :href="`/offers/${offer.id}`" class="text-brand">{{ offer.refNumber ?? offer.ref }}</a>
            </td>
            <td class="px-2 py-2">{{ offer.customerName }}</td>
            <td class="px-2 py-2 tabular-nums">{{ formatDate(offer.date) }}</td>
            <td class="px-2 py-2 text-right tabular-nums">{{ money.format(Number(offer.value ?? 0)) }}</td>
            <td class="px-2 py-2">{{ offer.state ? t(`offers.states.${offer.state}`) : "" }}</td>
            <td class="px-2 py-2">{{ offer.projectName }}</td>
          </tr>
        </tbody>

        <tfoot v-if="summary">
          <tr class="font-semibold" data-test="summary">
            <td class="px-2 py-2" colspan="3">
              {{ t("offers.summary", { count: summary.count }) }}
            </td>
            <td class="px-2 py-2 text-right tabular-nums" data-test="summary-value">
              {{ money.format(Number(summary.value)) }}
            </td>
            <td class="px-2 py-2" colspan="2"></td>
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
        {{ t("offers.previous") }}
      </button>

      <span class="text-sm text-muted" data-test="page">{{ page }}</span>

      <button
        type="button"
        class="rounded border border-field-border px-3 py-1 text-sm disabled:opacity-50"
        :disabled="!hasNextPage"
        data-test="next-page"
        @click="go({ page: page + 1 })"
      >
        {{ t("offers.next") }}
      </button>
    </nav>
  </div>
</template>

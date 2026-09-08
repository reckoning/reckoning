<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useInvoices, useInvoiceSummary } from "@/services/api/services/invoices/invoices"
import { useAccount } from "@/services/api/services/account/account"
import UiButton from "@/components/ui/UiButton.vue"
import UiDropdown from "@/components/ui/UiDropdown.vue"
import UiDropdownItem from "@/components/ui/UiDropdownItem.vue"
import UiFilter from "@/components/ui/UiFilter.vue"
import UiLabel from "@/components/ui/UiLabel.vue"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiPagination from "@/components/ui/UiPagination.vue"
import UiPanel from "@/components/ui/UiPanel.vue"
import UiSortHeader from "@/components/ui/UiSortHeader.vue"

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
// The server-rendered list printed `format: :month_year` — "%B %Y" — rather
// than a full date.
//
// `date` arrives as a bare YYYY-MM-DD. `new Date("2026-03-01")` is UTC
// midnight, and formatted in local time that is February west of Greenwich —
// so the anchor is read and printed in UTC.
const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, {month: "long", year: "numeric", timeZone: "UTC"}),
)

function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

// `invoice_label` in `app/helpers/invoices_helper.rb`, which is what coloured
// the state in the list.
const STATE_VARIANTS: Record<string, "default" | "primary" | "success"> = {
  created: "default",
  charged: "primary",
  paid: "success",
}

function stateVariant(state: string | null | undefined): "default" | "primary" | "success" {
  return STATE_VARIANTS[state ?? ""] ?? "primary"
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

// The filter names the states in the plural, the way `filter.invoice_state`
// does; a row names one of them.
const stateOptions = computed(() =>
  ["created", "charged", "paid"].map((state) => ({
    value: state,
    label: t(`invoices.filters.states.${state}`),
  })),
)

// The client cannot read the Link header through the generated mutator, so
// the filtered total answers it instead: a full last page would otherwise
// offer a next page that is empty.
const hasNextPage = computed(() => page.value * PER_PAGE < (summary.value?.count ?? 0))
</script>

<template>
  <div id="invoices">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow">
        {{ t("invoices.title") }}
        <br />
        <small class="block text-[65%] text-muted" data-test="summary">
          <span data-test="summary-value">
            {{ t("invoices.sum", { sum: money.format(Number(summary?.value ?? 0)) }) }}
          </span>
          <br />
          <span data-test="summary-vat">
            {{ t("invoices.vatSum", { sum: money.format(Number(summary?.vat ?? 0)) }) }}
          </span>
        </small>
      </h1>

      <div class="max-md:w-full">
        <RouterLink v-if="!limitReached" :to="{ name: 'invoice-new' }" data-test="new-invoice">
          <UiButton as="span" variant="primary" class="max-md:w-full">+ {{ t("invoices.new") }}</UiButton>
        </RouterLink>
        <UiButton
          v-else
          variant="primary"
          class="max-md:w-full"
          disabled
          :title="t('invoices.limitReached')"
          data-test="new-invoice-disabled"
        >
          + {{ t("invoices.new") }}
        </UiButton>
      </div>
    </div>

    <div class="mt-4 flex flex-wrap items-start justify-between gap-y-4">
      <div class="flex flex-wrap gap-1.5" data-test="filters">
        <UiFilter
          :label="t('invoices.filters.state')"
          :model-value="queryValue('state')"
          :options="stateOptions"
          :reset-title="t('invoices.filters.reset')"
          test="filter-state"
          @update:model-value="setFilter('state', $event)"
        />
        <UiFilter
          :label="t('invoices.filters.year')"
          :model-value="queryValue('year')"
          :options="yearOptions"
          :reset-title="t('invoices.filters.reset')"
          test="filter-year"
          @update:model-value="setFilter('year', $event)"
        />
        <UiFilter
          :label="t('invoices.filters.quarter')"
          :model-value="queryValue('quarter')"
          :options="quarterOptions"
          :reset-title="t('invoices.filters.reset')"
          test="filter-quarter"
          @update:model-value="setFilter('quarter', $event)"
        />
        <UiFilter
          :label="t('invoices.filters.month')"
          :model-value="queryValue('month')"
          :options="monthOptions"
          :reset-title="t('invoices.filters.reset')"
          test="filter-month"
          @update:model-value="setFilter('month', $event)"
        />
        <UiFilter
          :label="t('invoices.filters.paidInYear')"
          :model-value="queryValue('paid_in_year')"
          :options="yearOptions"
          :reset-title="t('invoices.filters.reset')"
          test="filter-paid-in-year"
          @update:model-value="setFilter('paid_in_year', $event)"
        />
        <UiFilter
          :label="t('invoices.filters.paidInQuarter')"
          :model-value="queryValue('paid_in_quarter')"
          :options="quarterOptions"
          :reset-title="t('invoices.filters.reset')"
          test="filter-paid-in-quarter"
          @update:model-value="setFilter('paid_in_quarter', $event)"
        />
        <UiFilter
          :label="t('invoices.filters.paidInMonth')"
          :model-value="queryValue('paid_in_month')"
          :options="monthOptions"
          :reset-title="t('invoices.filters.reset')"
          align="right"
          test="filter-paid-in-month"
          @update:model-value="setFilter('paid_in_month', $event)"
        />
      </div>

      <UiPagination
        :page="page"
        :has-next="hasNextPage"
        :previous-label="t('invoices.previous')"
        :next-label="t('invoices.next')"
        class="max-md:w-full"
        @go="go({ page: $event })"
      />
    </div>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("invoices.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("invoices.loadFailed") }}</p>
    <p v-else-if="invoices && invoices.length === 0" class="mt-4" data-test="empty">
      {{ t("invoices.empty") }}
    </p>

    <UiPanel v-else class="mt-4" list data-test="invoices">
      <template #heading>
        <div class="hidden grid-cols-12 gap-2 md:grid">
          <div class="col-span-1">
            <UiSortHeader column="ref" :label="t('invoices.columns.ref')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-4">
            <UiSortHeader column="customer" :label="t('invoices.columns.customer')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-2">
            <UiSortHeader column="date" :label="t('invoices.columns.date')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-2 text-right">
            <UiSortHeader column="value" :label="t('invoices.columns.value')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-1">
            <UiSortHeader column="state" :label="t('invoices.columns.state')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
        </div>
      </template>

      <UiListGroup>
        <UiListGroupItem
          v-for="invoice in invoices"
          :key="invoice.id"
          :data-test="`invoice-${invoice.id}`"
        >
          <div class="grid grid-cols-12 items-center gap-y-2 gap-x-2">
            <div class="col-span-6 tabular-nums md:col-span-1">
              {{ invoice.refNumber ?? invoice.ref }}
            </div>

            <!-- Below the grid's breakpoint the state moves up beside the
                 number, the way the server-rendered row did it. -->
            <div class="col-span-6 text-right md:hidden">
              <UiLabel :variant="stateVariant(invoice.state)">
                {{ invoice.state ? t(`invoices.states.${invoice.state}`) : "" }}
              </UiLabel>
            </div>

            <div class="col-span-12 md:col-span-4">
              <RouterLink
                :to="{ name: 'invoice', params: { id: invoice.id } }"
                class="text-ink hover:text-ink"
              >
                <strong>{{ invoice.customerName }}</strong>
                <span v-if="invoice.projectName"> - {{ invoice.projectName }}</span>
              </RouterLink>
            </div>

            <div class="col-span-6 md:col-span-2">{{ formatDate(invoice.date) }}</div>

            <div class="col-span-6 text-right tabular-nums md:col-span-2">
              <b>{{ money.format(Number(invoice.value ?? 0)) }}</b>
              <br />
              {{ money.format(Number(invoice.vat ?? 0)) }}
            </div>

            <div class="hidden md:col-span-1 md:block">
              <UiLabel :variant="stateVariant(invoice.state)">
                {{ invoice.state ? t(`invoices.states.${invoice.state}`) : "" }}
              </UiLabel>
            </div>

            <div class="col-span-12 md:col-span-2 md:text-right">
              <UiDropdown align="right" class="max-md:!flex max-md:w-full">
                <template #toggle="{ toggle }">
                  <UiButton
                    class="max-md:w-full"
                    :data-test="`actions-${invoice.id}`"
                    @click="toggle"
                  >
                    {{ t("invoices.actions") }}
                    <span class="bs-caret"></span>
                  </UiButton>
                </template>

                <template #menu>
                  <UiDropdownItem>
                    <RouterLink :to="{ name: 'invoice', params: { id: invoice.id } }">
                      {{ t("invoices.show") }}
                    </RouterLink>
                  </UiDropdownItem>
                  <UiDropdownItem v-if="invoice.abilities?.update">
                    <RouterLink :to="{ name: 'invoice-edit', params: { id: invoice.id } }">
                      {{ t("invoices.edit") }}
                    </RouterLink>
                  </UiDropdownItem>
                </template>
              </UiDropdown>
            </div>
          </div>
        </UiListGroupItem>
      </UiListGroup>
    </UiPanel>

    <UiPagination
      :page="page"
      :has-next="hasNextPage"
      :previous-label="t('invoices.previous')"
      :next-label="t('invoices.next')"
      @go="go({ page: $event })"
    />
  </div>
</template>

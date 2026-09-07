<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter } from "vue-router"
import { useI18n } from "vue-i18n"
import { useOffers, useOfferSummary } from "@/services/api/services/offers/offers"
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
// The server-rendered list printed `format: :month_year` — "%B %Y" — rather
// than a full date.
const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, {month: "long", year: "numeric", timeZone: "UTC"}),
)

function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

const yearOptions = computed(() =>
  (summary.value?.years ?? []).map((year) => ({value: String(year), label: String(year)})),
)

const STATES = ["created", "bided", "accepted", "declined", "canceled"] as const

// The filter names the states in the plural, the way `filter.offer_state`
// does; a row names one of them.
const stateOptions = computed(() =>
  STATES.map((state) => ({value: state, label: t(`offers.filters.states.${state}`)})),
)

// `offer_label` in the helper that went with the ERB list: a draft is grey,
// everything else the brand colour.
function stateVariant(state: string | null | undefined): "default" | "primary" {
  return state === "created" ? "default" : "primary"
}

// The client cannot read the Link header through the generated mutator, so
// the filtered total answers it instead: a full last page would otherwise
// offer a next page that is empty.
const hasNextPage = computed(() => page.value * PER_PAGE < (summary.value?.count ?? 0))
</script>

<template>
  <div id="offers">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow">
        {{ t("offers.title") }}
        <br />
        <small class="block text-[65%] text-muted" data-test="summary">
          <span data-test="summary-value">
            {{ t("offers.sum", { sum: money.format(Number(summary?.value ?? 0)) }) }}
          </span>
        </small>
      </h1>

      <div class="max-md:w-full">
        <a href="/offers/new" data-test="new-offer">
          <UiButton as="span" variant="primary" class="max-md:w-full">+ {{ t("offers.new") }}</UiButton>
        </a>
      </div>
    </div>

    <div class="mt-4 flex flex-wrap items-start justify-between gap-y-4">
      <div class="flex flex-wrap gap-1.5" data-test="filters">
        <UiFilter
          :label="t('offers.filters.state')"
          :model-value="queryValue('state')"
          :options="stateOptions"
          :reset-title="t('offers.filters.reset')"
          test="filter-state"
          @update:model-value="setFilter('state', $event)"
        />
        <UiFilter
          :label="t('offers.filters.year')"
          :model-value="queryValue('year')"
          :options="yearOptions"
          :reset-title="t('offers.filters.reset')"
          test="filter-year"
          @update:model-value="setFilter('year', $event)"
        />
      </div>

      <UiPagination
        :page="page"
        :has-next="hasNextPage"
        :previous-label="t('offers.previous')"
        :next-label="t('offers.next')"
        class="max-md:w-full"
        @go="go({ page: $event })"
      />
    </div>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("offers.loading") }}</p>
    <p v-else-if="isError" class="mt-4" data-test="error">{{ t("offers.loadFailed") }}</p>
    <p v-else-if="offers && offers.length === 0" class="mt-4" data-test="empty">
      {{ t("offers.empty") }}
    </p>

    <UiPanel v-else class="mt-4" list data-test="offers">
      <template #heading>
        <div class="hidden grid-cols-12 gap-2 md:grid">
          <div class="col-span-1">
            <UiSortHeader column="ref" :label="t('offers.columns.ref')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-4">
            <UiSortHeader column="customer" :label="t('offers.columns.customer')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-2">
            <UiSortHeader column="date" :label="t('offers.columns.date')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-2 text-right">
            <UiSortHeader column="value" :label="t('offers.columns.value')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
          <div class="col-span-1">
            <UiSortHeader column="state" :label="t('offers.columns.state')" :sort="sort" :direction="direction" @sort="sortBy" />
          </div>
        </div>
      </template>

      <UiListGroup>
        <UiListGroupItem v-for="offer in offers" :key="offer.id" :data-test="`offer-${offer.id}`">
          <div class="grid grid-cols-12 items-center gap-y-2 gap-x-2">
            <div class="col-span-6 tabular-nums md:col-span-1">
              {{ offer.refNumber ?? offer.ref }}
            </div>

            <div class="col-span-6 text-right md:hidden">
              <UiLabel :variant="stateVariant(offer.state)">
                {{ offer.state ? t(`offers.states.${offer.state}`) : "" }}
              </UiLabel>
            </div>

            <div class="col-span-12 md:col-span-4">
              <a :href="`/offers/${offer.id}`" class="text-ink hover:text-ink">
                <strong>{{ offer.customerName }}</strong>
                <span v-if="offer.projectName"> - {{ offer.projectName }}</span>
              </a>
            </div>

            <div class="col-span-6 md:col-span-2">{{ formatDate(offer.date) }}</div>

            <div class="col-span-6 text-right tabular-nums md:col-span-2">
              <b>{{ money.format(Number(offer.value ?? 0)) }}</b>
            </div>

            <div class="hidden md:col-span-1 md:block">
              <UiLabel :variant="stateVariant(offer.state)">
                {{ offer.state ? t(`offers.states.${offer.state}`) : "" }}
              </UiLabel>
            </div>

            <div class="col-span-12 md:col-span-2 md:text-right">
              <UiDropdown align="right" class="max-md:!flex max-md:w-full">
                <template #toggle="{ toggle }">
                  <UiButton class="max-md:w-full" :data-test="`actions-${offer.id}`" @click="toggle">
                    {{ t("offers.actions") }}
                    <span class="ml-1 inline-block border-t-4 border-r-4 border-l-4 border-transparent border-t-current"></span>
                  </UiButton>
                </template>

                <template #menu>
                  <UiDropdownItem>
                    <a :href="`/offers/${offer.id}`">{{ t("offers.show") }}</a>
                  </UiDropdownItem>
                  <UiDropdownItem v-if="offer.abilities?.update">
                    <a :href="`/offers/${offer.id}/edit`">{{ t("offers.edit") }}</a>
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
      :previous-label="t('offers.previous')"
      :next-label="t('offers.next')"
      @go="go({ page: $event })"
    />
  </div>
</template>

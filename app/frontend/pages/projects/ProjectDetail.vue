<script setup lang="ts">
import { computed } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useQueryClient } from "@tanstack/vue-query"
import {
  useProject,
  useProjectChart,
  getProjectQueryKey,
  getProjectChartQueryKey,
} from "@/services/api/services/projects/projects"
import { useInvoices } from "@/services/api/services/invoices/invoices"
import { useOffers } from "@/services/api/services/offers/offers"
import { projectBudgetChartOptions } from "@/lib/projectBudgetChart"
import type { ChartCategory } from "@/lib/chartBase"
import TimersCalendar from "@/islands/timers-calendar/TimersCalendar.vue"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiHighchart from "@/components/ui/UiHighchart.vue"
import UiLabel from "@/components/ui/UiLabel.vue"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiNavTabs from "@/components/ui/UiNavTabs.vue"
import UiPanel from "@/components/ui/UiPanel.vue"
import UiProgress from "@/components/ui/UiProgress.vue"

// The four tabs the server-rendered screen had, in its order.
const TABS = ["timers", "offers", "invoices", "tasks"] as const

type Tab = (typeof TABS)[number]

// A working day, which is what the hours are also given in.
const HOURS_PER_DAY = 8

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const queryClient = useQueryClient()

const id = computed(() => String(route.params.id))

const { data: project, isPending, isError } = useProject(id)
const { data: chart } = useProjectChart(id)
const {
  data: offers,
  isPending: offersPending,
  isError: offersFailed,
} = useOffers(computed(() => ({project_id: id.value, perPage: "all"})))
const {
  data: invoices,
  isPending: invoicesPending,
  isError: invoicesFailed,
} = useInvoices(computed(() => ({project_id: id.value, perPage: "all"})))

const active = computed<Tab>(() => {
  const hash = route.hash.replace("#", "")

  return TABS.some((tab) => tab === hash) ? (hash as Tab) : "timers"
})

const tabs = computed(() =>
  TABS.map((tab) => ({ key: tab, label: t(`projectDetail.tabs.${tab}`) })),
)

function open(tab: string): void {
  router.push({ hash: `#${tab}` })
}

const money = computed(
  () => new Intl.NumberFormat(locale.value, { style: "currency", currency: "EUR" }),
)
const numbers = computed(
  () =>
    new Intl.NumberFormat(locale.value, { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
)
const months = computed(
  () => new Intl.DateTimeFormat(locale.value, { month: "long", year: "numeric", timeZone: "UTC" }),
)
const dates = computed(
  () =>
    new Intl.DateTimeFormat(locale.value, {
      day: "2-digit",
      month: "long",
      year: "numeric",
      timeZone: "UTC",
    }),
)

function amount(value: string | number | null | undefined): string {
  return money.value.format(Number(value ?? 0))
}

function hours(value: string | number | null | undefined): string {
  return `${numbers.value.format(Number(value ?? 0))} h`
}

function days(value: number): string {
  return t("projectDetail.days", { count: Math.round(value / HOURS_PER_DAY) })
}

function month(value: string | null | undefined): string {
  return value ? months.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

// The numbers along the bottom of the panel. Each is `n/a` where what it
// would be worked out from is missing, rather than a zero that reads as an
// answer.
const budgetHours = computed(() => Number(project.value?.budgetHours ?? 0))
const budget = computed(() => Number(project.value?.budget ?? 0))
const rate = computed(() => project.value?.rate)

const remainingHours = computed(
  () => budgetHours.value - Number(project.value?.timerValuesBillable ?? 0),
)
const remainingBudget = computed(() => budget.value - Number(project.value?.invoiceValues ?? 0))
const uninvoiced = computed(
  () => Number(project.value?.timerValuesUninvoiced ?? 0) * Number(rate.value ?? 0),
)

const percent = computed(() => {
  const value = Number(project.value?.budgetPercent ?? 0)

  return Number.isFinite(value) ? Math.min(Math.max(value, 0), 100) : 0
})

// `budget_progress`: green while there is room, amber past 70, red past 90.
const progressVariant = computed<"success" | "warning" | "danger">(() => {
  if (percent.value > 90) return "danger"
  if (percent.value > 70) return "warning"

  return "success"
})

const weekOf = (label: string) => dates.value.format(new Date(`${label.slice(0, 10)}T00:00:00Z`))

// The series is read out here rather than inside the returned function, so
// that arriving data changes this function's identity and redraws the chart.
const build = computed(() => {
  const data = chart.value

  return (highlight: (category?: ChartCategory) => void) =>
    projectBudgetChartOptions({
      labels: data?.labels ?? [],
      datasets: data?.datasets ?? [],
      budget: data?.budget,
      ticks: data?.ticks,
      formatValue: (value: number) => money.value.format(value),
      // `invoicesChart`'s formatter, which this chart shares.
      formatAxis: (value: number) => (value < 1000 ? `${value} €` : `${value / 1000}k €`),
      monthShort: (label) => months.value.format(new Date(`${label.slice(0, 10)}T00:00:00Z`)),
      monthLong: weekOf,
      dateLabel: weekOf,
      budgetLabel: (formatted) => t("projectDetail.budgetEstimate", { amount: formatted }),
      onPointOver: highlight,
    })
})

// The island books time against this project, and three of the four numbers
// above are worked out from what it books.
async function refresh(): Promise<void> {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: getProjectQueryKey(id.value) }),
    queryClient.invalidateQueries({ queryKey: getProjectChartQueryKey(id.value) }),
  ])
}

const timerLabels = computed(() => ({
  weekDays: t("projectDetail.timers.weekDays"),
  today: t("projectDetail.timers.today"),
  addTimer: t("projectDetail.timers.addTimer"),
  dayShort: Array.from({ length: 7 }, (_, index) =>
    new Intl.DateTimeFormat(locale.value, { weekday: "short", timeZone: "UTC" }).format(
      new Date(Date.UTC(2024, 0, 1 + index)),
    ),
  ),
}))

const monthLabels = computed(() =>
  Array.from({ length: 12 }, (_, index) =>
    new Intl.DateTimeFormat(locale.value, { month: "long", timeZone: "UTC" }).format(
      new Date(Date.UTC(2024, index, 1)),
    ),
  ),
)
</script>

<template>
  <div id="project">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="project-title">{{ project?.name }}</h1>

      <div class="bs-btn-group max-md:w-full">
        <RouterLink :to="{ name: 'projects' }" data-test="back">
          <UiButton as="span">{{ t("projectDetail.back") }}</UiButton>
        </RouterLink>
        <RouterLink :to="{ name: 'project-edit', params: { id } }" data-test="edit">
          <UiButton as="span" variant="primary">
            <i class="fa fa-edit"></i>
            {{ t("projectDetail.edit") }}
          </UiButton>
        </RouterLink>
      </div>
    </div>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("projectDetail.loading") }}</p>

    <UiAlert v-else-if="isError || !project" variant="danger" class="mt-4" data-test="load-failed">
      {{ t("projectDetail.loadFailed") }}
    </UiAlert>

    <template v-else>
      <UiPanel class="mt-4" :title="t('projectDetail.budgetChart')" data-test="budget-panel">
        <template #body>
          <UiHighchart :build="build" size="chart-big" test="project-budget-chart" />

          <div class="bs-panel-progress">
            <UiProgress :percent="percent" :variant="progressVariant" data-test="budget-progress" />
          </div>

          <!-- The four numbers, in the order the server-rendered panel had
               them. Each says `n/a` where what it is worked out from is
               missing, rather than a zero that would read as an answer. -->
          <div class="-mx-4 -mb-4 grid grid-cols-2 md:grid-cols-4">
            <div class="bs-panel-box" data-test="box-hours">
              <h2>{{ t("projectDetail.boxes.hours") }}</h2>
              <div class="bs-panel-box-highlight">{{ hours(project.timerValues) }}</div>
              <div class="bs-panel-box-subline">
                <RouterLink :to="{ name: 'timesheet' }" data-test="add-timer">
                  <i class="fa fa-clock-o"></i>
                  {{ t("projectDetail.addTimer") }}
                </RouterLink>
              </div>
            </div>

            <div class="bs-panel-box" data-test="box-remaining-hours">
              <h2>{{ t("projectDetail.boxes.remainingHours") }}</h2>
              <div v-if="budgetHours > 0" class="bs-panel-box-highlight">
                {{ hours(remainingHours) }}
                <small>({{ days(remainingHours) }})</small>
              </div>
              <div v-else class="bs-panel-box-highlight is-blank">{{ t("projectDetail.na") }}</div>
              <div v-if="budgetHours > 0" class="bs-panel-box-subline flex justify-between gap-2">
                <span>{{ t("projectDetail.total") }}</span>
                <span class="text-right">
                  {{ hours(budgetHours) }}
                  ({{ days(budgetHours) }})
                </span>
              </div>
            </div>

            <div class="bs-panel-box" data-test="box-remaining-budget">
              <h2>{{ t("projectDetail.boxes.remainingBudget") }}</h2>
              <div v-if="budget > 0" class="bs-panel-box-highlight">
                {{ amount(remainingBudget) }}
              </div>
              <div v-else class="bs-panel-box-highlight is-blank">{{ t("projectDetail.na") }}</div>
              <div v-if="budget > 0" class="bs-panel-box-subline flex justify-between gap-2">
                <span>{{ t("projectDetail.total") }}</span>
                <span class="text-right">{{ amount(budget) }}</span>
              </div>
            </div>

            <div class="bs-panel-box" data-test="box-uninvoiced">
              <h2>{{ t("projectDetail.boxes.uninvoiced") }}</h2>
              <div v-if="rate" class="bs-panel-box-highlight">{{ amount(uninvoiced) }}</div>
              <div v-else class="bs-panel-box-highlight is-blank">{{ t("projectDetail.na") }}</div>
              <div class="bs-panel-box-subline">
                <RouterLink
                  :to="{ name: 'invoice-new', query: { project_id: id } }"
                  data-test="add-invoice"
                >
                  <i class="fa fa-plus"></i>
                  {{ t("projectDetail.addInvoice") }}
                </RouterLink>
              </div>
            </div>
          </div>
        </template>
      </UiPanel>

      <div class="mt-4">
        <UiNavTabs :tabs="tabs" :active="active" @select="open" />

        <div class="mt-4">
          <!-- The calendar books time against this project; it is the same
               component the server-rendered screen embedded as an island. -->
          <TimersCalendar
            v-if="active === 'timers'"
            :key="id"
            :project-id="id"
            :labels="timerLabels"
            :month-labels="monthLabels"
            data-test="timers-calendar"
            @changed="refresh"
          />

          <UiPanel v-else-if="active === 'offers'" list data-test="offers">
            <UiListGroup>
              <UiListGroupItem
                v-for="offer in offers ?? []"
                :key="offer.id"
                :to="{ name: 'offer', params: { id: offer.id } }"
                :data-test="`offer-${offer.id}`"
              >
                {{ offer.refNumber ?? offer.ref }} |
                <strong>{{ offer.customerName }}</strong>
                <div class="text-right">
                  <em>{{ month(offer.date) }}</em>
                </div>
              </UiListGroupItem>
              <UiListGroupItem v-if="offersPending" data-test="offers-loading">
                {{ t("projectDetail.loading") }}
              </UiListGroupItem>
              <UiListGroupItem v-else-if="offersFailed" data-test="offers-error">
                {{ t("offers.loadFailed") }}
              </UiListGroupItem>
              <UiListGroupItem v-else-if="(offers?.length ?? 0) === 0" data-test="offers-empty">
                {{ t("projectDetail.noOffers") }}
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>

          <UiPanel v-else-if="active === 'invoices'" list data-test="invoices">
            <UiListGroup>
              <UiListGroupItem
                v-for="invoice in invoices ?? []"
                :key="invoice.id"
                :to="{ name: 'invoice', params: { id: invoice.id } }"
                :data-test="`invoice-${invoice.id}`"
              >
                {{ invoice.refNumber ?? invoice.ref }} |
                <strong>{{ invoice.customerName }}</strong>
                <div class="text-right">
                  <em>{{ month(invoice.date) }}</em>
                </div>
              </UiListGroupItem>
              <UiListGroupItem v-if="invoicesPending" data-test="invoices-loading">
                {{ t("projectDetail.loading") }}
              </UiListGroupItem>
              <UiListGroupItem v-else-if="invoicesFailed" data-test="invoices-error">
                {{ t("invoices.loadFailed") }}
              </UiListGroupItem>
              <UiListGroupItem
                v-else-if="(invoices?.length ?? 0) === 0"
                data-test="invoices-empty"
              >
                {{ t("projectDetail.noInvoices") }}
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>

          <UiPanel v-else list data-test="tasks">
            <UiListGroup>
              <UiListGroupItem
                v-for="task in project.tasks ?? []"
                :key="task.id"
                :data-test="`task-${task.id}`"
              >
                {{ task.name }}
                <span class="float-right">
                  <UiLabel :variant="task.billable ? 'primary' : 'default'">
                    {{ task.billable ? t("projectDetail.billable") : t("projectDetail.notBillable") }}
                  </UiLabel>
                </span>
              </UiListGroupItem>
              <UiListGroupItem v-if="(project.tasks?.length ?? 0) === 0" data-test="tasks-empty">
                {{ t("projectDetail.noTasks") }}
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>
        </div>
      </div>
    </template>
  </div>
</template>

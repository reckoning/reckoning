<script setup lang="ts">
import { computed } from "vue"
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useDashboard } from "@/services/api/services/dashboard/dashboard"
import { useInvoices } from "@/services/api/services/invoices/invoices"
import { useProjects } from "@/services/api/services/projects/projects"
import type { Invoice, Project } from "@/services/api/models"
import { useCurrentUserStore } from "@/stores/currentUser"
import UiChart from "@/components/ui/UiChart.vue"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiLabel from "@/components/ui/UiLabel.vue"
import UiPanel from "@/components/ui/UiPanel.vue"
import UiProgress from "@/components/ui/UiProgress.vue"

const { t, locale } = useI18n()
const currentUser = useCurrentUserStore()

const { data: totals, isPending } = useDashboard()

const year = computed(() => totals.value?.year ?? new Date().getUTCFullYear())

// The three lists the server-rendered dashboard shows in full — it never
// paged them either.
const { data: chargedInvoices } = useInvoices({state: "charged", perPage: "all"})
const { data: paidInvoices } = useInvoices(
  computed(() => ({paid_in_year: year.value, perPage: "all"})),
)
const { data: lastYearInvoices } = useInvoices(
  computed(() => ({paid_in_year: year.value - 1, perPage: "all"})),
)
const { data: projects } = useProjects({state: "active"})

const money = computed(
  () => new Intl.NumberFormat(locale.value, {style: "currency", currency: "EUR"}),
)
const hours = computed(
  () => new Intl.NumberFormat(locale.value, {minimumFractionDigits: 2, maximumFractionDigits: 2}),
)
// The invoice rows print month and year, as `format: :month_year` did.
const months = computed(
  () => new Intl.DateTimeFormat(locale.value, {month: "long", year: "numeric", timeZone: "UTC"}),
)

function amount(value: number | string | null | undefined): string {
  return money.value.format(Number(value ?? 0))
}

function formatHours(value: number | string | null | undefined): string {
  return `${hours.value.format(Number(value ?? 0))} h`
}

function formatMonth(value: string | null | undefined): string {
  return value ? months.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

// The chart's own labels: `%b` along the axis, `%B` in the tooltip's header,
// as `date.formats.month_short` and `month` gave Highcharts.
const shortMonths = computed(
  () => new Intl.DateTimeFormat(locale.value, {month: "short", timeZone: "UTC"}),
)
const longMonths = computed(
  () => new Intl.DateTimeFormat(locale.value, {month: "long", timeZone: "UTC"}),
)

function monthShort(label: string): string {
  return shortMonths.value.format(new Date(`${label.slice(0, 10)}T00:00:00Z`))
}

function monthLong(label: string): string {
  return longMonths.value.format(new Date(`${label.slice(0, 10)}T00:00:00Z`))
}

// `invoicesChart`'s own formatter: whole euros below a thousand, thousands
// above it — `0 €`, `500 €`, `1.5k €`, `8k €`. Deliberately not the currency
// formatter, which would put two decimals on every line of the axis.
function axisAmount(value: number): string {
  if (value < 1000) return `${value} €`

  return `${value / 1000}k €`
}

// `all_invoices` is the two sums added up, the way the ERB row did it.
const allInvoices = computed(
  () => Number(totals.value?.chargedSum ?? 0) + Number(totals.value?.paidSum ?? 0),
)

// `overtime_label`, `weekly_hours_label` and `daily_hours_label`: green while
// the hours are within a quarter of what was scheduled, amber to two and a
// half times it, red beyond.
type Level = "success" | "warning" | "danger"

function level(value: number, reference: number): Level {
  if (value < reference * 1.25 && value > reference * -1.25) return "success"
  if (value < reference * 2.5 && value > reference * -2.5) return "warning"

  return "danger"
}

const overtime = computed(() => totals.value?.overtime)

const weeklyLevel = computed(() => level(Number(overtime.value?.weeklyHours ?? 0), 40))
const dailyLevel = computed(() => level(Number(overtime.value?.dailyHours ?? 0), 8))

function customerLevel(hoursOff: number | string | null | undefined, weekly: number | string | null | undefined): Level {
  return level(Number(hoursOff ?? 0), Number(weekly ?? 0) / 5)
}

// `projects.active.with_budget`, ordered as the panel had them.
const budgets = computed(() =>
  (projects.value ?? []).filter((project: Project) => Number(project.budget ?? 0) > 0),
)

function overdue(invoice: Invoice): boolean {
  const due = invoice.paymentDueDate

  return invoice.state === "charged" && !!due && new Date(`${due.slice(0, 10)}T00:00:00Z`) < new Date()
}

const nothingBilled = computed(
  () =>
    (chargedInvoices.value?.length ?? 0) === 0 &&
    (paidInvoices.value?.length ?? 0) === 0 &&
    (lastYearInvoices.value?.length ?? 0) === 0,
)

const chart = computed(() => totals.value?.chart)
</script>

<template>
  <div id="dashboard">
    <h1 data-test="dashboard-title">{{ t("dashboard.title") }}</h1>

    <p v-if="currentUser.user" class="sr-only" data-test="dashboard-greeting">
      {{ t("dashboard.greeting", { email: currentUser.user.email }) }}
    </p>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("dashboard.loading") }}</p>

    <div v-else class="mt-4 grid gap-x-6 md:grid-cols-3">
      <div>
        <UiPanel :title="t('dashboard.panels.overtime')" data-test="overtime-panel">
          <UiListGroup>
            <UiListGroupItem
              v-for="customer in overtime?.customers ?? []"
              :key="customer.name ?? ''"
              :variant="customerLevel(customer.hours, customer.weeklyHours)"
            >
              {{ customer.name }}
              <strong class="float-right">{{ formatHours(customer.hours) }}</strong>
            </UiListGroupItem>

            <UiListGroupItem :variant="weeklyLevel" data-test="weekly-hours">
              {{ t("dashboard.panels.weeklyHours") }}
              <strong class="float-right">{{ formatHours(overtime?.weeklyHours) }}</strong>
            </UiListGroupItem>

            <UiListGroupItem :variant="dailyLevel" data-test="daily-hours">
              {{ t("dashboard.panels.dailyHours") }}
              <strong class="float-right">{{ formatHours(overtime?.dailyHours) }}</strong>
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>

        <UiPanel :title="t('dashboard.panels.summary')" data-test="summary-panel">
          <UiListGroup>
            <UiListGroupItem>
              {{ t("dashboard.panels.uninvoiced") }}
              <strong class="float-right" data-test="uninvoiced">{{ amount(totals?.uninvoicedAmount) }}</strong>
            </UiListGroupItem>
            <UiListGroupItem>
              {{ t("dashboard.panels.chargedInvoices") }}
              <strong class="float-right" data-test="charged-sum">{{ amount(totals?.chargedSum) }}</strong>
            </UiListGroupItem>
            <UiListGroupItem>
              {{ t("dashboard.panels.paidInvoices") }}
              <strong class="float-right" data-test="paid-sum">{{ amount(totals?.paidSum) }}</strong>
            </UiListGroupItem>
            <UiListGroupItem>
              {{ t("dashboard.panels.allInvoices") }}
              <strong class="float-right" data-test="all-sum">{{ amount(allInvoices) }}</strong>
            </UiListGroupItem>
            <UiListGroupItem muted>
              {{ t("dashboard.panels.lastInvoices", { year: year - 1 }) }}
              <strong class="float-right">{{ amount(totals?.lastYearPaidSum) }}</strong>
            </UiListGroupItem>

            <!-- Both rows only exist with a provision rate on the account. -->
            <UiListGroupItem v-if="totals?.provision != null" data-test="provision">
              {{ t("dashboard.panels.provision") }}
              <strong class="float-right">{{ amount(totals.provision) }}</strong>
            </UiListGroupItem>
            <UiListGroupItem v-if="totals?.lastYearProvision != null" muted>
              {{ t("dashboard.panels.lastProvision", { year: year - 1 }) }}
              <strong class="float-right">{{ amount(totals.lastYearProvision) }}</strong>
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>

        <UiPanel :title="t('dashboard.panels.expenses.title')" data-test="expenses-panel">
          <UiListGroup>
            <UiListGroupItem>
              {{ t("dashboard.panels.expenses.current") }}
              <strong class="float-right" data-test="expenses-sum">{{ amount(totals?.expensesSum) }}</strong>
            </UiListGroupItem>
            <UiListGroupItem muted>
              {{ t("dashboard.panels.expenses.last") }}
              <strong class="float-right">{{ amount(totals?.lastYearExpensesSum) }}</strong>
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>

        <UiPanel
          v-if="budgets.length > 0"
          :title="t('dashboard.panels.budgets')"
          data-test="budgets-panel"
        >
          <UiListGroup>
            <UiListGroupItem v-for="project in budgets" :key="project.id" interactive>
              <a :href="`/projects/${project.id}`" class="text-ink hover:text-ink">
                {{ project.customerName ? `${project.name} (${project.customerName})` : project.name }}
              </a>
              <UiProgress
                class="mt-1"
                :percent="Number(project.budgetPercent ?? 0)"
                :data-test="`budget-${project.id}`"
              />
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>
      </div>

      <div class="md:col-span-2">
        <UiPanel
          v-if="(chargedInvoices?.length ?? 0) > 0"
          variant="warning"
          :title="t('dashboard.panels.chargedInvoices')"
          data-test="charged-invoices"
        >
          <UiListGroup>
            <UiListGroupItem v-for="invoice in chargedInvoices ?? []" :key="invoice.id" interactive>
              <RouterLink :to="{ name: 'invoice', params: { id: invoice.id } }" class="text-ink hover:text-ink">
                {{ invoice.refNumber ?? invoice.ref }} |
                <strong>{{ invoice.customerName }}</strong>
                <span v-if="invoice.projectName"> - {{ invoice.projectName }}</span>
              </RouterLink>
              <div class="text-right">
                <em>{{ formatMonth(invoice.date) }}</em>
              </div>
              <UiLabel v-if="overdue(invoice)" variant="danger">
                {{ t("dashboard.overdue") }}
              </UiLabel>
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>

        <UiPanel :title="t('dashboard.panels.invoicesChart', { year })">
          <template #body>
            <UiChart
              v-if="chart"
              :labels="chart.labels ?? []"
              :datasets="chart.datasets ?? []"
              :format-value="(value: number) => money.format(value)"
              :format-axis="axisAmount"
              :month-short="monthShort"
              :month-long="monthLong"
            />
          </template>
        </UiPanel>

        <UiPanel
          v-if="(paidInvoices?.length ?? 0) > 0"
          variant="success"
          :title="t('dashboard.panels.paidInvoices')"
          data-test="paid-invoices"
        >
          <UiListGroup>
            <UiListGroupItem v-for="invoice in paidInvoices ?? []" :key="invoice.id" interactive>
              <RouterLink :to="{ name: 'invoice', params: { id: invoice.id } }" class="text-ink hover:text-ink">
                {{ invoice.refNumber ?? invoice.ref }} |
                <strong>{{ invoice.customerName }}</strong>
                <span v-if="invoice.projectName"> - {{ invoice.projectName }}</span>
              </RouterLink>
              <div class="text-right">
                <em>{{ formatMonth(invoice.date) }}</em>
              </div>
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>

        <UiPanel
          v-if="(lastYearInvoices?.length ?? 0) > 0"
          :title="t('dashboard.panels.lastInvoices', { year: year - 1 })"
          data-test="last-year-invoices"
        >
          <UiListGroup>
            <UiListGroupItem v-for="invoice in lastYearInvoices ?? []" :key="invoice.id" interactive>
              <RouterLink :to="{ name: 'invoice', params: { id: invoice.id } }" class="text-ink hover:text-ink">
                {{ invoice.refNumber ?? invoice.ref }} |
                <strong>{{ invoice.customerName }}</strong>
                <span v-if="invoice.projectName"> - {{ invoice.projectName }}</span>
              </RouterLink>
              <div class="text-right">
                <em>{{ formatMonth(invoice.date) }}</em>
              </div>
            </UiListGroupItem>
          </UiListGroup>
        </UiPanel>

        <p v-if="nothingBilled" class="text-muted" data-test="nothing-billed">
          {{ t("dashboard.nothingBilled") }}
        </p>
      </div>
    </div>
  </div>
</template>

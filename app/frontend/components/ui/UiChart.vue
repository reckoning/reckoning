<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from "vue"
import { useI18n } from "vue-i18n"
import { Highcharts, type HighchartsChart } from "@/lib/highcharts"
import { invoicesChartOptions, type ChartCategory, type ChartDataset } from "@/lib/invoicesChart"

// The dashboard's invoice chart, drawn by the same Highcharts build and the
// same options the server-rendered dashboard uses — the config itself never
// depended on jQuery, only the code around it did.
const props = defineProps<{
  labels: string[]
  datasets: ChartDataset[]
  formatValue: (value: number) => string
  formatAxis: (value: number) => string
  monthShort: (label: string) => string
  monthLong: (label: string) => string
}>()

const { t } = useI18n()

const container = ref<HTMLElement>()
let chart: HighchartsChart | undefined

// The month under the pointer is spelled out in bold, which the old chart did
// by reaching for the label out of the point's mouseOver handler.
function highlight(category?: ChartCategory): void {
  const labels = container.value?.querySelectorAll(".highcharts-xaxis-labels span")

  labels?.forEach((label) => {
    label.classList.toggle("hover", label.textContent === category?.short)
  })
}

function draw(): void {
  if (!container.value) return

  chart?.destroy()

  const options = invoicesChartOptions({
    labels: props.labels,
    datasets: props.datasets,
    formatValue: props.formatValue,
    formatAxis: props.formatAxis,
    monthShort: props.monthShort,
    monthLong: props.monthLong,
    onPointOver: highlight,
  })

  chart = new Highcharts.Chart({
    ...options,
    chart: { ...(options.chart as object), renderTo: container.value },
  })
}

onMounted(() => {
  Highcharts.setOptions({ lang: { noData: t("chart.noData") } })
  draw()
})

// Redrawn rather than updated in place: the dashboard hands over a whole year
// at once, and a fresh chart cannot disagree with the props.
watch(() => [props.labels, props.datasets], draw, { deep: true })

onBeforeUnmount(() => {
  chart?.destroy()
  chart = undefined
})
</script>

<template>
  <div class="chart chart-dashboard" data-test="invoices-chart" @mouseleave="highlight()">
    <div ref="container" class="chart-inner"></div>
  </div>
</template>

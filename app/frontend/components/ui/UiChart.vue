<script setup lang="ts">
import { computed } from "vue"
import { invoicesChartOptions } from "@/lib/invoicesChart"
import type { ChartCategory, ChartDataset } from "@/lib/chartBase"
import UiHighchart from "./UiHighchart.vue"

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

// Read out here rather than inside the returned function, so that arriving
// data changes this function's identity and redraws the chart.
const build = computed(() => {
  const { labels, datasets, formatValue, formatAxis, monthShort, monthLong } = props

  return (highlight: (category?: ChartCategory) => void) =>
    invoicesChartOptions({
      labels,
      datasets,
      formatValue,
      formatAxis,
      monthShort,
      monthLong,
      onPointOver: highlight,
    })
})
</script>

<template>
  <UiHighchart :build="build" test="invoices-chart" />
</template>

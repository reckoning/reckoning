<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from "vue"
import { useI18n } from "vue-i18n"
import { Highcharts, type HighchartsChart } from "@/lib/highcharts"
import type { ChartCategory } from "@/lib/chartBase"

// Mounts one chart from the options it is handed, and owns the one piece of
// behaviour that needs the rendered element: the label under the pointer is
// spelled out in bold, which the old charts did out of the point's mouseOver
// handler. `build` is a function rather than a plain object so that handler
// can reach in here.
const props = defineProps<{
  build: (highlight: (category?: ChartCategory) => void) => Record<string, unknown>
  /** `.chart-dashboard` on the dashboard, `.chart-big` on a project. */
  size?: string
  test?: string
}>()

const { t } = useI18n()

const container = ref<HTMLElement>()
let chart: HighchartsChart | undefined

function highlight(category?: ChartCategory): void {
  const labels = container.value?.querySelectorAll(".highcharts-xaxis-labels span")

  labels?.forEach((label) => {
    label.classList.toggle("hover", label.textContent === category?.short)
  })
}

function draw(): void {
  if (!container.value) return

  chart?.destroy()

  const options = props.build(highlight)

  chart = new Highcharts.Chart({
    ...options,
    chart: { ...(options.chart as object), renderTo: container.value },
  })
}

onMounted(() => {
  Highcharts.setOptions({ lang: { noData: t("chart.noData") } })
  draw()
})

// Redrawn rather than updated in place: what arrives is a whole series at
// once, and a fresh chart cannot disagree with it.
watch(() => props.build, draw)

onBeforeUnmount(() => {
  chart?.destroy()
  chart = undefined
})
</script>

<template>
  <div class="chart" :class="size ?? 'chart-dashboard'" :data-test="test" @mouseleave="highlight()">
    <div ref="container" class="chart-inner"></div>
  </div>
</template>

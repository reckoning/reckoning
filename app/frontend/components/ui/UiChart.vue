<script setup lang="ts">
import { computed, ref } from "vue"

// The dashboard's invoice chart. The server-rendered one is Highcharts; this
// draws the same picture as plain SVG — a library of 300 KB for twelve points
// a year would be a poor trade, and phase C is meant to drop Highcharts, d3
// and nvd3 rather than carry one of them into the SPA.
//
// What it reproduces, because the old chart is read by hovering it: the shared
// tooltip with every series' value at the month under the pointer, the
// crosshair, the band over the current month, the dashed continuation past
// `zone` — the part of the year that has not happened yet — and the `k €`
// axis.
interface Series {
  name?: string | null
  color?: string | null
  data: (number | string)[]
  zone?: number | null
}

const props = defineProps<{
  labels: string[]
  datasets: Series[]
  formatValue: (value: number) => string
  formatAxis?: (value: number) => string
  monthShort?: (label: string) => string
  monthLong?: (label: string) => string
}>()

const WIDTH = 640
const HEIGHT = 240
const PADDING = {top: 12, right: 12, bottom: 28, left: 58}

const series = computed(() =>
  props.datasets.map((dataset) => ({
    name: dataset.name ?? "",
    color: dataset.color ?? "currentColor",
    points: dataset.data.map((value) => Number(value ?? 0)),
    // A missing zone means the whole series is real: the months of a year
    // that has already passed.
    zone: dataset.zone ?? dataset.data.length - 1,
  })),
)

const maximum = computed(() => Math.max(1, ...series.value.flatMap((entry) => entry.points)))

function x(index: number): number {
  const inner = WIDTH - PADDING.left - PADDING.right

  return PADDING.left + (inner * index) / Math.max(1, props.labels.length - 1)
}

function y(value: number): number {
  const inner = HEIGHT - PADDING.top - PADDING.bottom

  return PADDING.top + inner - (inner * value) / maximum.value
}

function path(points: number[], from: number, to: number): string {
  return points
    .slice(from, to + 1)
    .map((value, index) => `${index === 0 ? "M" : "L"}${x(from + index)},${y(value)}`)
    .join(" ")
}

const ticks = computed(() => [0, maximum.value / 2, maximum.value])

const axis = computed(() => props.formatAxis ?? props.formatValue)

// `getCurrentWeek` in `app/assets/javascripts/app/chart.coffee`: the band
// covers the slot before the first label that lies in the future — the month
// in progress.
const currentIndex = computed(() => {
  const now = Date.now()
  const index = props.labels.findIndex(
    (label) => new Date(`${label.slice(0, 10)}T00:00:00Z`).getTime() >= now,
  )

  return index <= 0 ? -1 : index - 1
})

const hovered = ref<number | null>(null)

function onMove(event: MouseEvent): void {
  const target = event.currentTarget as SVGSVGElement
  const box = target.getBoundingClientRect()
  const scaled = ((event.clientX - box.left) / box.width) * WIDTH
  const inner = WIDTH - PADDING.left - PADDING.right
  const step = inner / Math.max(1, props.labels.length - 1)
  const index = Math.round((scaled - PADDING.left) / step)

  hovered.value = index >= 0 && index < props.labels.length ? index : null
}

const readings = computed(() => {
  const index = hovered.value
  if (index === null) return []

  return series.value
    .filter((entry) => index < entry.points.length)
    .map((entry) => ({name: entry.name, color: entry.color, value: entry.points[index]}))
})

// The box follows the pointer but stays inside the chart.
const tooltipLeft = computed(() => {
  const index = hovered.value
  if (index === null) return 0

  return Math.min(Math.max(x(index) / WIDTH, 0.02), 0.72) * 100
})

function short(label: string): string {
  return props.monthShort ? props.monthShort(label) : label.slice(5, 7)
}

function long(label: string): string {
  return props.monthLong ? props.monthLong(label) : label.slice(0, 7)
}
</script>

<template>
  <figure class="relative m-0" data-test="invoices-chart">
    <svg
      :viewBox="`0 0 ${WIDTH} ${HEIGHT}`"
      class="w-full"
      role="img"
      @mousemove="onMove"
      @mouseleave="hovered = null"
    >
      <!-- The month in progress, as the plot band marked it. -->
      <rect
        v-if="currentIndex >= 0"
        :x="x(currentIndex) - (WIDTH - PADDING.left - PADDING.right) / Math.max(1, labels.length - 1) / 2"
        :y="PADDING.top"
        :width="(WIDTH - PADDING.left - PADDING.right) / Math.max(1, labels.length - 1)"
        :height="HEIGHT - PADDING.top - PADDING.bottom"
        fill="rgba(155, 200, 255, 0.2)"
        data-test="current-month"
      />

      <g class="text-muted">
        <template v-for="tick in ticks" :key="tick">
          <line
            :x1="PADDING.left"
            :x2="WIDTH - PADDING.right"
            :y1="y(tick)"
            :y2="y(tick)"
            stroke="currentColor"
            stroke-opacity="0.25"
          />
          <text :x="PADDING.left - 6" :y="y(tick) + 4" text-anchor="end" font-size="10" fill="currentColor">
            {{ axis(tick) }}
          </text>
        </template>

        <text
          v-for="(label, index) in labels"
          :key="label"
          :x="x(index)"
          :y="HEIGHT - 8"
          text-anchor="middle"
          font-size="10"
          fill="currentColor"
          :class="index === hovered ? 'font-bold text-ink' : ''"
        >
          {{ short(label) }}
        </text>
      </g>

      <!-- The crosshair under the pointer. -->
      <line
        v-if="hovered !== null"
        :x1="x(hovered)"
        :x2="x(hovered)"
        :y1="PADDING.top"
        :y2="HEIGHT - PADDING.bottom"
        stroke="rgba(200, 200, 200, 0.8)"
        stroke-width="1"
        data-test="crosshair"
      />

      <template v-for="entry in series" :key="entry.name">
        <path :d="path(entry.points, 0, entry.zone)" fill="none" stroke-width="2" :stroke="entry.color" />
        <!-- Past the zone the year has not happened yet. -->
        <path
          v-if="entry.zone < entry.points.length - 1"
          :d="path(entry.points, entry.zone, entry.points.length - 1)"
          fill="none"
          stroke-width="2"
          stroke-dasharray="4 3"
          :stroke="entry.color"
          :data-test="`forecast-${entry.name}`"
        />
        <circle
          v-if="hovered !== null && hovered < entry.points.length"
          :cx="x(hovered)"
          :cy="y(entry.points[hovered])"
          r="3.5"
          :fill="entry.color"
        />
      </template>
    </svg>

    <!-- The shared tooltip: the month, then every series with its value. -->
    <div
      v-if="hovered !== null && readings.length > 0"
      class="bs-panel pointer-events-none absolute top-2 z-10 !mb-0 min-w-44 text-small"
      :style="{ left: `${tooltipLeft}%` }"
      data-test="chart-tooltip"
    >
      <div class="bs-panel-heading bs-panel-heading-tight bg-surface-muted">
        <strong>{{ long(labels[hovered]) }}</strong>
      </div>
      <div class="px-3 py-2">
        <div v-for="reading in readings" :key="reading.name" class="flex items-baseline gap-2">
          <span :style="{ color: reading.color }" aria-hidden="true">●</span>
          <span class="grow">{{ reading.name }}</span>
          <strong class="tabular-nums">{{ formatValue(reading.value) }}</strong>
        </div>
      </div>
    </div>
  </figure>
</template>

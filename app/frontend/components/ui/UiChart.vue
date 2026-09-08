<script setup lang="ts">
import { computed } from "vue"

// The dashboard's invoice chart. The server-rendered one is nvd3 on top of
// d3; this draws the same series as plain SVG, because a chart of twelve
// points per year does not need 300 KB of library — and the colours are the
// ones `Charts::InvoicesService` already picks.
interface Series {
  name?: string | null
  color?: string | null
  data: (number | string)[]
}

const props = defineProps<{labels: string[]; datasets: Series[]; formatValue: (value: number) => string}>()

const WIDTH = 640
const HEIGHT = 220
const PADDING = {top: 12, right: 12, bottom: 26, left: 56}

const series = computed(() =>
  props.datasets.map((dataset) => ({
    name: dataset.name ?? "",
    color: dataset.color ?? "currentColor",
    points: dataset.data.map((value) => Number(value ?? 0)),
  })),
)

const maximum = computed(() => {
  const values = series.value.flatMap((entry) => entry.points)

  return Math.max(1, ...values)
})

// The x axis is the twelve months; a series that stops early (the current
// year) simply ends where its data does.
function x(index: number): number {
  const inner = WIDTH - PADDING.left - PADDING.right

  return PADDING.left + (inner * index) / Math.max(1, props.labels.length - 1)
}

function y(value: number): number {
  const inner = HEIGHT - PADDING.top - PADDING.bottom

  return PADDING.top + inner - (inner * value) / maximum.value
}

function path(points: number[]): string {
  return points.map((value, index) => `${index === 0 ? "M" : "L"}${x(index)},${y(value)}`).join(" ")
}

const ticks = computed(() => [0, maximum.value / 2, maximum.value])

const monthLabels = computed(() =>
  props.labels.map((label) => label.slice(5, 7)),
)
</script>

<template>
  <figure class="m-0" data-test="invoices-chart">
    <svg :viewBox="`0 0 ${WIDTH} ${HEIGHT}`" class="w-full" role="img">
      <!-- The grid, and the value at each line. -->
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
            {{ formatValue(tick) }}
          </text>
        </template>

        <text
          v-for="(month, index) in monthLabels"
          :key="month + index"
          :x="x(index)"
          :y="HEIGHT - 8"
          text-anchor="middle"
          font-size="10"
          fill="currentColor"
        >
          {{ month }}
        </text>
      </g>

      <path
        v-for="entry in series"
        :key="entry.name"
        :d="path(entry.points)"
        fill="none"
        stroke-width="2"
        :stroke="entry.color"
      />
    </svg>

    <figcaption class="mt-2 flex flex-wrap gap-3 text-small text-muted">
      <span v-for="entry in series" :key="`legend-${entry.name}`" class="flex items-center gap-1">
        <span class="inline-block h-0.5 w-4" :style="{ backgroundColor: entry.color }"></span>
        {{ entry.name }}
      </span>
    </figcaption>
  </figure>
</template>

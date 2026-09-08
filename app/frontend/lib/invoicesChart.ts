import type {HighchartsPoint} from "@/lib/highcharts"

export interface ChartDataset {
  name?: string | null
  color?: string | null
  data?: (number | string)[] | null
  zone?: number | null
}

export interface ChartCategory {
  short: string
  long: string
}

export interface ChartOptionsInput {
  labels: string[]
  datasets: ChartDataset[]
  formatValue: (value: number) => string
  formatAxis: (value: number) => string
  monthShort: (label: string) => string
  monthLong: (label: string) => string
  onPointOver?: (category: ChartCategory) => void
  now?: Date
}

// `getCurrentWeek`: the band covers the last period that has begun, half a
// category either side of it, so it reads as a bar over the whole month.
export function currentPeriod(labels: string[], now: Date): {from: number; to: number} {
  for (let index = 0; index < labels.length; index += 1) {
    if (new Date(labels[index]) >= now) return {from: index - 1.5, to: index - 0.5}
  }

  return {from: 0, to: 0}
}

export function invoicesChartOptions(input: ChartOptionsInput): Record<string, unknown> {
  const period = currentPeriod(input.labels, input.now ?? new Date())

  const categories: ChartCategory[] = input.labels.map((label) => ({
    short: input.monthShort(label),
    long: input.monthLong(label),
  }))

  const series = input.datasets.map((dataset) => {
    const data = (dataset.data ?? []).map((value) => parseFloat(String(value)))

    return {
      color: dataset.color ?? undefined,
      name: dataset.name ?? "",
      marker: {symbol: "circle", enabled: false},
      data,
      zoneAxis: "x",
      zones: [{value: dataset.zone ?? data.length - 1}, {dashStyle: "shortdash"}],
    }
  })

  return {
    chart: {type: "line"},
    credits: {enabled: false},
    title: {text: null},
    noData: {style: {fontSize: "18px", fontWeight: "bold", color: "#ccc"}},
    plotOptions: {
      series: {
        point: {
          events: {
            mouseOver(this: HighchartsPoint) {
              input.onPointOver?.(this.category)
            },
          },
        },
      },
    },
    xAxis: {
      categories,
      title: {text: null},
      labels: {
        format: "{value.short}",
        useHTML: true,
        reserveSpace: false,
        autoRotation: 0,
        step: 1,
      },
      plotBands: [{color: "rgba(155, 200, 255, 0.2)", from: period.from, to: period.to}],
    },
    yAxis: {
      startOnTick: false,
      title: {text: null},
      labels: {
        formatter(this: {value: number}) {
          return input.formatAxis(this.value)
        },
      },
    },
    tooltip: {
      useHTML: true,
      backgroundColor: null,
      borderWidth: 0,
      shadow: false,
      style: {padding: 0},
      shared: true,
      // A category-wide crosshair, which Highcharts draws as a band across the
      // whole month rather than a hairline.
      crosshairs: [{color: "rgba(200, 200, 200, 0.2)"}],
      headerFormat: '<div class="highcharts-tooltip-header"><b>{point.key.long}</b></div>',
      pointFormatter(this: HighchartsPoint) {
        const value = input.formatValue(this.y)

        return (
          `<div><div style="float: left;"><span style="color:${this.color}">●</span> ` +
          `${this.series.name}: </div><div style="float: right;"><b>${value}</b></div></div>`
        )
      },
    },
    navigation: {buttonOptions: {enabled: false}},
    legend: {enabled: false},
    series,
  }
}

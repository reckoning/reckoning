import {baseChartOptions, type ChartInput} from "@/lib/chartBase"

export interface ProjectBudgetChartInput extends ChartInput {
  formatAxis: (value: number) => string
  /** The line the work is measured against, and its label. */
  budget?: string | number | null
  budgetLabel: (amount: string) => string
  /** The weeks a month begins in — where the axis is labelled. */
  ticks?: number[] | null
}

interface HighchartsInstance {
  plotWidth: number
  plotLeft: number
  pointCount: number
  xAxis: {tickPositions: number[]}[]
  yAxis: {min: number; max: number; toPixels: (value: number) => number}[]
  renderer: {text: (text: string, x: number, y: number, useHTML?: boolean) => {add: () => void}}
  container: HTMLElement
}

// Highcharts 4.2.5 hangs a `flat` property off the plot line's path array and
// only labels a line whose array does not answer to `flat` — which every array
// does since ES2019, so the label the old chart configured has not been drawn
// for years. It is drawn here instead, where the plot line's own offsets
// (`x: 10`, `y: -4`) and `.highcharts-plotline-budget` still place it.
function drawBudgetLabel(chart: HighchartsInstance, value: number, text: string): void {
  const axis = chart.yAxis[0]

  if (!axis || value < axis.min || value > axis.max) return

  chart.renderer.text(text, chart.plotLeft + 10, axis.toPixels(value) - 4, true).add()
}

// `budgetChart`: the same base as the dashboard's, with a week per category
// instead of a month, the budget drawn across it, and the axis labelled only
// where a month begins.
export function projectBudgetChartOptions(
  input: ProjectBudgetChartInput,
): Record<string, unknown> {
  const options = baseChartOptions(input)
  const series = options.series as {data: number[]}[]
  const budget = input.budget === null || input.budget === undefined ? undefined : Number(input.budget)
  const budgetLabel =
    budget === undefined
      ? undefined
      : `<span class="bs-label bg-muted highcharts-plotline-budget">${input.budgetLabel(
          input.formatValue(budget),
        )}</span>`

  return {
    ...options,
    chart: {
      ...(options.chart as object),
      events: {
        // A month's label belongs over the middle of that month, not over the
        // week the axis put its tick in. Highcharts has no say in where a
        // `useHTML` label sits once it is drawn, so the old chart moved them
        // itself on load — this is that, without jQuery.
        load(this: HighchartsInstance) {
          if (!series[0]) return

          if (budget !== undefined && budgetLabel) drawBudgetLabel(this, budget, budgetLabel)

          const width = this.plotWidth / this.pointCount
          const labels = this.container.querySelectorAll<HTMLElement>(
            ".highcharts-xaxis-labels span",
          )

          let previous = -1

          this.xAxis[0].tickPositions.forEach((position, index) => {
            const label = labels[index]
            if (!label) return

            let left = this.plotLeft
            let segment = 0

            for (let point = 0; point < this.pointCount; point += 1) {
              if (point > position) break

              left += width
              if (point > previous) segment += width
            }

            previous = position
            label.style.left = `${left - segment / 2 - label.offsetWidth / 2 - 1}px`
          })
        },
      },
    },
    xAxis: {
      ...(options.xAxis as object),
      tickPositions: input.ticks ?? [],
    },
    yAxis: {
      ...(options.yAxis as object),
      // A series that starts at zero keeps the axis Highcharts would pick;
      // anything else is measured from zero.
      min: series[0] && Number(series[0].data[0]) === 0 ? undefined : 0,
      labels: {
        useHTML: true,
        formatter(this: {value: number}) {
          return input.formatAxis(this.value)
        },
      },
      plotLines:
        budget === undefined
          ? []
          : [
              {
                value: budget,
                color: "#777777",
                width: 2,
              },
            ],
    },
    tooltip: {
      ...(options.tooltip as object),
      // The whole date, because a category here is a week rather than a
      // month.
      headerFormat: '<div class="highcharts-tooltip-header"><b>{point.key.date}</b></div>',
    },
  }
}

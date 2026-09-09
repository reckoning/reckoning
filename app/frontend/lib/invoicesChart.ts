import {baseChartOptions, type ChartInput} from "@/lib/chartBase"

export type {ChartCategory, ChartDataset} from "@/lib/chartBase"
export {currentPeriod} from "@/lib/chartBase"

export interface InvoicesChartInput extends ChartInput {
  formatAxis: (value: number) => string
}

// `invoicesChart`: the base with its own axis, which reads in thousands.
export function invoicesChartOptions(input: InvoicesChartInput): Record<string, unknown> {
  const options = baseChartOptions(input)

  return {
    ...options,
    yAxis: {
      ...(options.yAxis as object),
      labels: {
        formatter(this: {value: number}) {
          return input.formatAxis(this.value)
        },
      },
    },
  }
}

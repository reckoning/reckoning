import {describe, it, expect, vi} from "vitest"
import {projectBudgetChartOptions} from "./projectBudgetChart"

const LABELS = ["2026-01-05", "2026-01-12", "2026-02-02"]

function options(overrides: Record<string, unknown> = {}) {
  return projectBudgetChartOptions({
    labels: LABELS,
    datasets: [{name: "Budget", color: "#428bca", data: [100, 250, 400], zone: 1}],
    budget: "10000.0",
    ticks: [0, 2],
    formatValue: (value) => `${value} €`,
    formatAxis: (value) => (value < 1000 ? `${value} €` : `${value / 1000}k €`),
    monthShort: (label) => label.slice(5, 7),
    monthLong: (label) => `Week of ${label}`,
    dateLabel: (label) => `Week of ${label}`,
    budgetLabel: (amount) => `Budget estimate: ${amount}`,
    now: new Date("2026-01-20"),
    ...overrides,
  })
}

// The chart Highcharts hands its `load` handler, with only what the handler
// reaches for.
function fakeChart(yAxis: {min: number; max: number} = {min: 0, max: 12500}) {
  return {
    plotWidth: 600,
    plotLeft: 60,
    pointCount: 3,
    xAxis: [{tickPositions: [0, 2]}],
    yAxis: [{...yAxis, toPixels: (value: number) => 100 - value / 1000}],
    renderer: {text: vi.fn(() => ({add: vi.fn()}))},
    container: {querySelectorAll: () => []} as unknown as HTMLElement,
  }
}

function load(chartOptions: Record<string, unknown>) {
  const {events} = chartOptions.chart as {events: {load: (this: unknown) => void}}

  return (chart: unknown) => events.load.call(chart)
}

describe("projectBudgetChartOptions", () => {
  // A week per category here, so the axis is labelled only where a month
  // begins — which is what the service sends the ticks for.
  it("labels the axis only at the weeks a month begins in", () => {
    const xAxis = options().xAxis as {tickPositions: number[]}

    expect(xAxis.tickPositions).toEqual([0, 2])
  })

  // The line the work is measured against.
  it("draws the budget across the chart", () => {
    const yAxis = options().yAxis as {plotLines: {value: number; width: number}[]}

    expect(yAxis.plotLines[0].value).toBe(10000)
    expect(yAxis.plotLines[0].width).toBe(2)
  })

  // Highcharts' own plot line label never renders on a modern browser, so the
  // amount is spelled out onto the line by hand once the chart is drawn.
  it("spells the budget out onto the line", () => {
    const chart = fakeChart()

    load(options())(chart)

    expect(chart.renderer.text).toHaveBeenCalledWith(
      expect.stringContaining("Budget estimate: 10000 €"),
      70,
      86,
      true,
    )
  })

  it("leaves a budget off the chart unlabelled", () => {
    const chart = fakeChart({min: 0, max: 5000})

    load(options())(chart)

    expect(chart.renderer.text).not.toHaveBeenCalled()
  })

  it("draws no line for a project without a budget", () => {
    const yAxis = options({budget: null}).yAxis as {plotLines: unknown[]}

    expect(yAxis.plotLines).toEqual([])
  })

  // A series that starts at zero keeps the axis Highcharts would choose;
  // anything else is measured from zero.
  it("measures from zero unless the series already starts there", () => {
    expect((options().yAxis as {min?: number}).min).toBe(0)

    const fromZero = options({
      datasets: [{name: "Budget", color: "#428bca", data: [0, 100], zone: 1}],
    })

    expect((fromZero.yAxis as {min?: number}).min).toBeUndefined()
  })

  // A category is a week, so the tooltip names the day rather than the month
  // the dashboard's chart names.
  it("heads the tooltip with the week", () => {
    const tooltip = options().tooltip as {headerFormat: string}
    const xAxis = options().xAxis as {categories: {date: string}[]}

    expect(tooltip.headerFormat).toContain("point.key.date")
    expect(xAxis.categories[0].date).toBe("Week of 2026-01-05")
  })

  it("keeps what both charts share — the dashed rest and no legend", () => {
    const series = options().series as {zones: {value?: number; dashStyle?: string}[]}[]

    expect(series[0].zones).toEqual([{value: 1}, {dashStyle: "shortdash"}])
    expect(options().legend).toEqual({enabled: false})
  })
})

import {describe, it, expect} from "vitest"
import {currentPeriod, invoicesChartOptions, type ChartDataset} from "./invoicesChart"

const LABELS = Array.from({length: 12}, (_, index) => {
  const month = String(index + 1).padStart(2, "0")

  return `2026-${month}-01`
})

const DATASETS: ChartDataset[] = [
  {name: "Summe", color: "#428bca", data: ["100", "250", 400], zone: 1},
  {name: "Monat", color: "#dcdcdc", data: [100, 150, 150]},
]

function options(datasets = DATASETS, now = new Date("2026-03-14")) {
  return invoicesChartOptions({
    labels: LABELS,
    datasets,
    formatValue: (value) => `${value} €`,
    formatAxis: (value) => (value < 1000 ? `${value} €` : `${value / 1000}k €`),
    monthShort: (label) => `M${label.slice(5, 7)}`,
    monthLong: (label) => `Monat ${label.slice(5, 7)}`,
    now,
  })
}

describe("currentPeriod", () => {
  it("bands the month in progress, a category wide", () => {
    expect(currentPeriod(LABELS, new Date("2026-03-14"))).toEqual({from: 1.5, to: 2.5})
  })

  it("bands nothing once the whole range is in the past", () => {
    expect(currentPeriod(LABELS, new Date("2027-01-01"))).toEqual({from: 0, to: 0})
  })
})

describe("invoicesChartOptions", () => {
  it("reads the values as numbers, whether the API sent strings or not", () => {
    const series = options().series as {data: number[]}[]

    expect(series[0].data).toEqual([100, 250, 400])
  })

  it("dashes the series past its zone", () => {
    const series = options().series as {zones: {value?: number; dashStyle?: string}[]}[]

    expect(series[0].zones).toEqual([{value: 1}, {dashStyle: "shortdash"}])
  })

  it("dashes nothing for a series that reaches the end of the range", () => {
    const series = options().series as {zones: {value?: number}[]}[]

    expect(series[1].zones[0].value).toBe(2)
  })

  it("labels the months in the caller's language", () => {
    const xAxis = options().xAxis as {categories: {short: string; long: string}[]}

    expect(xAxis.categories[0]).toEqual({short: "M01", long: "Monat 01"})
  })

  it("marks the month in progress", () => {
    const xAxis = options().xAxis as {plotBands: {from: number; to: number}[]}

    expect(xAxis.plotBands[0]).toMatchObject({from: 1.5, to: 2.5})
  })

  it("formats the axis as thousands", () => {
    const yAxis = options().yAxis as {labels: {formatter: () => string}}

    expect(yAxis.labels.formatter.call({value: 8000})).toBe("8k €")
    expect(yAxis.labels.formatter.call({value: 500})).toBe("500 €")
  })

  it("shares one tooltip between the series and crosshairs the month", () => {
    const tooltip = options().tooltip as {shared: boolean; crosshairs: {color: string}[]}

    expect(tooltip.shared).toBe(true)
    expect(tooltip.crosshairs[0].color).toBe("rgba(200, 200, 200, 0.2)")
  })

  it("names every series and its value in the tooltip", () => {
    const tooltip = options().tooltip as {pointFormatter: () => string}
    const point = {y: 250, color: "#428bca", series: {name: "Summe"}}

    expect(tooltip.pointFormatter.call(point)).toContain("Summe")
    expect(tooltip.pointFormatter.call(point)).toContain("250 €")
  })

  it("keeps the legend off, as the panel titles say what the lines are", () => {
    expect(options().legend).toEqual({enabled: false})
  })
})

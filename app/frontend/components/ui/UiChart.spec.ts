import {describe, it, expect} from "vitest"
import {mount} from "@vue/test-utils"
import UiChart from "./UiChart.vue"

// A year of months, so the current-month band and the dashed continuation
// have something to sit on.
const LABELS = Array.from({length: 12}, (_, index) => {
  const month = String(index + 1).padStart(2, "0")

  return `${new Date().getUTCFullYear()}-${month}-01`
})

interface Series {
  name: string
  color: string
  data: (number | string)[]
  zone?: number | null
}

function mountChart(datasets: Series[], labels = LABELS) {
  return mount(UiChart, {
    props: {
      labels,
      datasets,
      formatValue: (value: number) => `${Math.round(value)} €`,
      formatAxis: (value: number) => (value < 1000 ? `${value} €` : `${value / 1000}k €`),
      monthShort: (label: string) => label.slice(5, 7),
      monthLong: (label: string) => `Monat ${label.slice(5, 7)}`,
    },
  })
}

const RUNNING: Series = {
  name: "Summe",
  color: "#428bca",
  data: Array.from({length: 12}, (_, index) => (index + 1) * 100),
  zone: 3,
}

describe("UiChart", () => {
  // No legend: Highcharts had it switched off, and the series are named in
  // the tooltip instead.
  it("draws one line per series, in the colour it was given", () => {
    const wrapper = mountChart([RUNNING, {name: "Monate", color: "#dcdcdc", data: [50, 60, 70]}])

    expect(wrapper.findAll('path[stroke="#428bca"]').length).toBeGreaterThan(0)
    expect(wrapper.findAll('path[stroke="#dcdcdc"]').length).toBeGreaterThan(0)
    expect(wrapper.text()).not.toContain("Summe")
  })

  // Past `zone` the year has not happened yet, which the old chart drew as a
  // dashed continuation.
  it("dashes the part of the year that has not happened", () => {
    const wrapper = mountChart([RUNNING])

    const forecast = wrapper.get('[data-test="forecast-Summe"]')

    expect(forecast.attributes("stroke-dasharray")).toBe("4 3")
    // It starts where the solid part ends.
    expect(forecast.attributes("d")?.startsWith("M")).toBe(true)
  })

  it("leaves a finished year solid", () => {
    const wrapper = mountChart([{...RUNNING, zone: 11}])

    expect(wrapper.find('[data-test="forecast-Summe"]').exists()).toBe(false)
  })

  // The band Highcharts drew over the month in progress.
  it("marks the month in progress", () => {
    const wrapper = mountChart([RUNNING])

    expect(wrapper.find('[data-test="current-month"]').exists()).toBe(true)
  })

  it("marks nothing when every month is in the past", () => {
    const wrapper = mountChart([{name: "Summe", color: "#428bca", data: [1, 2]}], [
      "2020-01-01",
      "2020-02-01",
    ])

    expect(wrapper.find('[data-test="current-month"]').exists()).toBe(false)
  })

  // The chart is read by hovering it: a crosshair, and every series' value at
  // that month in one box.
  it("shows a crosshair and every series at the month under the pointer", async () => {
    const wrapper = mountChart([RUNNING, {name: "Monate", color: "#dcdcdc", data: [50, 60, 70]}])

    expect(wrapper.find('[data-test="chart-tooltip"]').exists()).toBe(false)

    const svg = wrapper.get("svg")
    svg.element.getBoundingClientRect = () => ({width: 640, left: 0, height: 240, top: 0}) as DOMRect
    await svg.trigger("mousemove", {clientX: 58})

    expect(wrapper.find('[data-test="crosshair"]').exists()).toBe(true)

    const tooltip = wrapper.get('[data-test="chart-tooltip"]')

    expect(tooltip.text()).toContain("Monat 01")
    expect(tooltip.text()).toContain("Summe")
    expect(tooltip.text()).toContain("100 €")
    expect(tooltip.text()).toContain("50 €")
  })

  // A series that stops early has no value at a later month, so it stays out
  // of the box rather than reporting a zero it does not have.
  it("leaves a series out of the box where it has no value", async () => {
    const wrapper = mountChart([RUNNING, {name: "Monate", color: "#dcdcdc", data: [50, 60, 70]}])

    const svg = wrapper.get("svg")
    svg.element.getBoundingClientRect = () => ({width: 640, left: 0, height: 240, top: 0}) as DOMRect
    await svg.trigger("mousemove", {clientX: 400})

    const tooltip = wrapper.get('[data-test="chart-tooltip"]')

    expect(tooltip.text()).toContain("Summe")
    expect(tooltip.text()).not.toContain("Monate")
  })

  it("hides the box again when the pointer leaves", async () => {
    const wrapper = mountChart([RUNNING])
    const svg = wrapper.get("svg")
    svg.element.getBoundingClientRect = () => ({width: 640, left: 0, height: 240, top: 0}) as DOMRect

    await svg.trigger("mousemove", {clientX: 100})
    expect(wrapper.find('[data-test="chart-tooltip"]').exists()).toBe(true)

    await svg.trigger("mouseleave")
    expect(wrapper.find('[data-test="chart-tooltip"]').exists()).toBe(false)
  })

  // The axis reads in thousands, the way `invoicesChart` formatted it.
  it("prints the axis through the formatter it was given", () => {
    const wrapper = mountChart([{name: "Summe", color: "#428bca", data: [0, 4000]}])

    expect(wrapper.text()).toContain("4k €")
  })

  // Decimals cross the wire as strings, and an empty account must not divide
  // by zero.
  it("reads string values and survives an empty account", () => {
    const strings = mountChart([{name: "Summe", color: "#428bca", data: ["100.0", "0.0"]}])
    expect(strings.get("path").attributes("d")).not.toContain("NaN")

    const empty = mountChart([{name: "Summe", color: "#428bca", data: [0, 0]}])
    expect(empty.get("path").attributes("d")).not.toContain("NaN")
  })
})

import {describe, it, expect} from "vitest"
import {mount} from "@vue/test-utils"
import UiChart from "./UiChart.vue"

const LABELS = ["2026-01-01", "2026-02-01", "2026-03-01"]

function mountChart(datasets: {name: string; color: string; data: (number | string)[]}[]) {
  return mount(UiChart, {
    props: {labels: LABELS, datasets, formatValue: (value: number) => String(Math.round(value))},
  })
}

describe("UiChart", () => {
  it("draws one line per series, in the colour it was given", () => {
    const wrapper = mountChart([
      {name: "2026", color: "#428bca", data: [100, 200, 300]},
      {name: "2025", color: "#dcdcdc", data: [50, 60, 70]},
    ])

    const paths = wrapper.findAll("path")

    expect(paths).toHaveLength(2)
    expect(paths[0].attributes("stroke")).toBe("#428bca")
    expect(wrapper.text()).toContain("2026")
  })

  // The current year's series stops at the month it has reached; the line has
  // to end there rather than fall to zero.
  it("ends a short series where its data ends", () => {
    const wrapper = mountChart([{name: "2026", color: "#428bca", data: [100, 200]}])

    const commands = wrapper.get("path").attributes("d")?.split(" ") ?? []

    expect(commands).toHaveLength(2)
  })

  // Decimals cross the wire as strings.
  it("reads values that arrive as strings", () => {
    const wrapper = mountChart([{name: "2026", color: "#428bca", data: ["100.0", "0.0", "50.0"]}])

    expect(wrapper.get("path").attributes("d")).not.toContain("NaN")
  })

  // An empty account still has axes rather than a division by zero.
  it("draws an empty chart without falling over", () => {
    const wrapper = mountChart([{name: "2026", color: "#428bca", data: [0, 0, 0]}])

    expect(wrapper.get("path").attributes("d")).not.toContain("NaN")
    expect(wrapper.findAll("line").length).toBeGreaterThan(0)
  })
})

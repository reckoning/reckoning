import {describe, it, expect} from "vitest"
import {mount} from "@vue/test-utils"
import WeekCell from "./WeekCell.vue"
import type {Timer} from "../../../lib/timers/types"

function makeTimer(overrides: Partial<Timer> = {}): Timer {
  return {
    id: "t1",
    date: "2026-06-10",
    value: 1,
    note: null,
    sumForTask: 0,
    started: false,
    startedAt: null,
    startTime: null,
    startTimeForTask: null,
    positionId: null,
    invoiced: false,
    taskId: "task1",
    taskName: "Task",
    taskLabel: "Label",
    taskBillable: true,
    projectId: "p1",
    projectName: "Project",
    projectCustomerName: null,
    createdAt: "",
    updatedAt: "",
    deleted: false,
    links: {project: {href: ""}},
    ...overrides,
  }
}

function mountCell(timersForDate: Timer[]) {
  return mount(WeekCell, {
    props: {date: "2026-06-10", taskId: "task1", timersForDate},
  })
}

describe("WeekCell", () => {
  it("renders invoiced timers read-only (no input)", () => {
    const wrapper = mountCell([makeTimer({value: 2, positionId: "pos-1"})])

    expect(wrapper.find("input").exists()).toBe(false)
    expect(wrapper.find(".invoiced").exists()).toBe(true)
    expect(wrapper.text()).toContain("2:00")
  })

  it("renders a running timer read-only with a spinner", () => {
    const wrapper = mountCell([
      makeTimer({value: 0, started: true, startedAt: "2026-06-10T10:00:00.000Z"}),
    ])

    expect(wrapper.find("input").exists()).toBe(false)
    expect(wrapper.find(".started").exists()).toBe(true)
    expect(wrapper.find('[data-test="running-spinner"]').exists()).toBe(true)
  })

  it("shows an empty input when there are no timers", () => {
    const wrapper = mountCell([])

    const input = wrapper.find("input")
    expect(input.exists()).toBe(true)
    expect((input.element as HTMLInputElement).value).toBe("")
  })

  it("pre-fills the input with the summed hours of existing timers", () => {
    const wrapper = mountCell([makeTimer({value: 1}), makeTimer({id: "t2", value: 0.5})])

    expect((wrapper.find("input").element as HTMLInputElement).value).toBe("1:30")
  })

  it("emits save with the parsed hours and existing timers on blur", async () => {
    const existing: Timer[] = []
    const wrapper = mountCell(existing)
    const input = wrapper.find("input")

    await input.setValue("1:30")
    await input.trigger("blur")

    const saves = wrapper.emitted("save")
    expect(saves).toHaveLength(1)
    expect(saves![0][0]).toMatchObject({
      date: "2026-06-10",
      taskId: "task1",
      sumHours: 1.5,
      existing,
    })
  })

  it("does not emit save when the value is unchanged", async () => {
    const wrapper = mountCell([makeTimer({value: 2})])
    const input = wrapper.find("input")

    await input.setValue("2:00")
    await input.trigger("blur")

    expect(wrapper.emitted("save")).toBeUndefined()
  })
})

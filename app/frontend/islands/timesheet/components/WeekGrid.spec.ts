import {describe, it, expect, beforeEach, vi} from "vitest"
import {mount, flushPromises} from "@vue/test-utils"
import type {Timer} from "../../../lib/timers/types"
import type {TaskWithTimers} from "../../../lib/timers/api"

// Spies shared with the mocked modules (hoisted above the imports).
const {refresh, createTimer, updateTimer, deleteTimer} = vi.hoisted(() => ({
  refresh: vi.fn(),
  createTimer: vi.fn(() => Promise.resolve({})),
  updateTimer: vi.fn(() => Promise.resolve({})),
  deleteTimer: vi.fn(() => Promise.resolve()),
}))

vi.mock("../composables/useWeekTasks", async () => {
  const {ref} = await import("vue")
  return {
    useWeekTasks: () => ({
      tasks: ref([
        {
          id: "task1",
          projectId: "p1",
          projectName: "Project",
          projectCustomerName: null,
          label: "Label",
          timers: [] as Timer[],
        },
      ]),
      loading: ref(false),
      error: ref(null),
      refresh,
    }),
  }
})

vi.mock("../../../lib/timers/api", () => ({createTimer, updateTimer, deleteTimer}))

import WeekGrid from "./WeekGrid.vue"
import WeekCell from "./WeekCell.vue"

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

function mountGrid(extraTasks?: TaskWithTimers[]) {
  return mount(WeekGrid, {
    props: {
      weekDate: "2026-06-10",
      dayShortLabels: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"],
      addTaskLabel: "Aufgabe hinzufügen",
      extraTasks,
    },
  })
}

function makeRow(id: string): TaskWithTimers {
  return {
    id,
    name: "Task",
    label: "Label",
    billable: true,
    projectId: "p1",
    projectName: "Project",
    projectCustomerName: null,
    timers: [],
  }
}

async function emitSave(
  wrapper: ReturnType<typeof mountGrid>,
  payload: {date: string; taskId: string; sumHours: number; existing: Timer[]},
) {
  await wrapper.findComponent(WeekCell).vm.$emit("save", payload)
  await flushPromises()
}

describe("WeekGrid rows", () => {
  it("renders tasks added this session that the week fetch does not return", () => {
    const wrapper = mountGrid([makeRow("task2")])

    expect(wrapper.findAll(".panel.panel-default")).toHaveLength(2)
  })

  it("does not duplicate an added task once the fetch returns it", () => {
    const wrapper = mountGrid([makeRow("task1")])

    expect(wrapper.findAll(".panel.panel-default")).toHaveLength(1)
  })
})

describe("WeekGrid save semantics", () => {
  beforeEach(() => vi.clearAllMocks())

  it("creates a timer when the cell was empty", async () => {
    const wrapper = mountGrid()

    await emitSave(wrapper, {date: "2026-06-10", taskId: "task1", sumHours: 1.5, existing: []})

    expect(createTimer).toHaveBeenCalledWith(
      {date: "2026-06-10", value: 1.5, note: null, taskId: "task1"},
      false,
    )
    expect(updateTimer).not.toHaveBeenCalled()
    expect(deleteTimer).not.toHaveBeenCalled()
    expect(refresh).toHaveBeenCalledOnce()
  })

  it("deletes every existing timer when the new sum is zero", async () => {
    const wrapper = mountGrid()
    const existing = [makeTimer({id: "a"}), makeTimer({id: "b"})]

    await emitSave(wrapper, {date: "2026-06-10", taskId: "task1", sumHours: 0, existing})

    expect(deleteTimer).toHaveBeenCalledTimes(2)
    expect(deleteTimer).toHaveBeenCalledWith("a")
    expect(deleteTimer).toHaveBeenCalledWith("b")
    expect(createTimer).not.toHaveBeenCalled()
    expect(updateTimer).not.toHaveBeenCalled()
  })

  it("absorbs the delta into the last timer, preserving older ones", async () => {
    const wrapper = mountGrid()
    const existing = [
      makeTimer({id: "old", value: 1}),
      makeTimer({id: "last", value: 0.5, note: "keep"}),
    ]

    // new sum 3h; older timers sum to 1h → last becomes 2h
    await emitSave(wrapper, {date: "2026-06-10", taskId: "task1", sumHours: 3, existing})

    expect(updateTimer).toHaveBeenCalledOnce()
    expect(updateTimer).toHaveBeenCalledWith(
      "last",
      {date: "2026-06-10", value: 2, note: "keep", taskId: "task1"},
      false,
    )
    expect(createTimer).not.toHaveBeenCalled()
    expect(deleteTimer).not.toHaveBeenCalled()
  })
})

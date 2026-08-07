import {describe, it, expect} from "vitest"
import {
  parseHHMM,
  formatHHMM,
  runningDuration,
  weekDays,
  weekRange,
  addDays,
} from "./format"

describe("parseHHMM", () => {
  it("parses HH:MM into fractional hours", () => {
    expect(parseHHMM("01:30")).toBe(1.5)
    expect(parseHHMM("2:15")).toBeCloseTo(2.25, 10)
    expect(parseHHMM("0:45")).toBeCloseTo(0.75, 10)
  })

  it("parses decimal input, accepting comma or dot", () => {
    expect(parseHHMM("1.5")).toBe(1.5)
    expect(parseHHMM("1,5")).toBe(1.5)
  })

  it("treats empty or invalid input as zero", () => {
    expect(parseHHMM("")).toBe(0)
    expect(parseHHMM("   ")).toBe(0)
    expect(parseHHMM("abc")).toBe(0)
  })
})

describe("formatHHMM", () => {
  it("formats fractional hours with un-padded hours and padded minutes", () => {
    expect(formatHHMM(7.75)).toBe("7:45")
    expect(formatHHMM(1.5)).toBe("1:30")
    expect(formatHHMM(0.75)).toBe("0:45")
    expect(formatHHMM(10)).toBe("10:00")
  })

  it("clamps invalid or negative input to 0:00", () => {
    expect(formatHHMM(0)).toBe("0:00")
    expect(formatHHMM(-1)).toBe("0:00")
    expect(formatHHMM(NaN)).toBe("0:00")
  })

  it("round-trips with parseHHMM", () => {
    for (const v of [0.25, 1.5, 2.75, 8]) {
      expect(parseHHMM(formatHHMM(v))).toBeCloseTo(v, 10)
    }
  })
})

describe("runningDuration", () => {
  const startedAt = "2026-06-10T10:00:00.000Z"
  const startedMs = Date.parse(startedAt)

  it("adds elapsed wall-clock time to the stored value", () => {
    // one hour later, with one stored hour → 2:00
    expect(runningDuration(startedAt, 1, startedMs + 3600000)).toBe("2:00")
    // 30 minutes later, no stored value → 0:30
    expect(runningDuration(startedAt, 0, startedMs + 1800000)).toBe("0:30")
  })

  it("falls back to the stored value when startedAt is unparseable", () => {
    expect(runningDuration("not-a-date", 1.5, startedMs)).toBe("1:30")
  })
})

describe("weekDays", () => {
  it("returns seven consecutive ISO dates, Monday through Sunday", () => {
    const days = weekDays("2026-06-10")

    expect(days).toHaveLength(7)
    expect(days).toContain("2026-06-10")
    expect(new Date(days[0]).getUTCDay()).toBe(1) // Monday
    expect(new Date(days[6]).getUTCDay()).toBe(0) // Sunday

    for (let i = 1; i < days.length; i++) {
      expect(days[i]).toBe(addDays(days[i - 1], 1))
    }
  })
})

describe("weekRange", () => {
  it("spans the Monday and Sunday of the containing ISO week", () => {
    const {startDate, endDate} = weekRange("2026-06-10")
    expect(new Date(startDate).getUTCDay()).toBe(1)
    expect(new Date(endDate).getUTCDay()).toBe(0)
    expect(startDate <= "2026-06-10").toBe(true)
    expect(endDate >= "2026-06-10").toBe(true)
  })
})

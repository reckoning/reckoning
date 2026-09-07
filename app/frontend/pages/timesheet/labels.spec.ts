import {describe, it, expect, afterEach} from "vitest"
import {weekdayNames, monthNames} from "./labels"

const original = process.env.TZ

describe("timesheet labels", () => {
  afterEach(() => {
    process.env.TZ = original
  })

  it("starts the week on Monday", () => {
    expect(weekdayNames("en", "long")[0]).toBe("Monday")
    expect(weekdayNames("de", "long")[0]).toBe("Montag")
  })

  it("names the twelve months in order", () => {
    expect(monthNames("en")[0]).toBe("January")
    expect(monthNames("en")[11]).toBe("December")
  })

  // The anchors are UTC midnights. Formatted in local time west of Greenwich
  // they land on the previous day, and every label slips by one.
  it("holds up west of Greenwich", () => {
    process.env.TZ = "America/Los_Angeles"

    expect(weekdayNames("en", "long")[0]).toBe("Monday")
    expect(monthNames("en")[0]).toBe("January")
  })
})

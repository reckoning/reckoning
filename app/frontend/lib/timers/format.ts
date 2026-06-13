// Shared date / time helpers for timer-related Vue islands
// (timers-calendar, timesheet). Calendar-grid-specific helpers
// (e.g. `buildWeeks` for a 5-6 row month grid) live in the
// individual island so this stays generic.

import dayjs from "dayjs"
import isoWeek from "dayjs/plugin/isoWeek"
import customParseFormat from "dayjs/plugin/customParseFormat"

dayjs.extend(isoWeek)
dayjs.extend(customParseFormat)

export const ISO_DATE = "YYYY-MM-DD"

export function todayISO(): string {
  return dayjs().format(ISO_DATE)
}

export function startOfMonth(dateISO: string): string {
  return dayjs(dateISO, ISO_DATE).startOf("month").format(ISO_DATE)
}

export function addMonths(dateISO: string, n: number): string {
  return dayjs(dateISO, ISO_DATE).add(n, "month").format(ISO_DATE)
}

export function addDays(dateISO: string, n: number): string {
  return dayjs(dateISO, ISO_DATE).add(n, "day").format(ISO_DATE)
}

export function startOfIsoWeek(dateISO: string): string {
  return dayjs(dateISO, ISO_DATE).startOf("isoWeek").format(ISO_DATE)
}

export function endOfIsoWeek(dateISO: string): string {
  return dayjs(dateISO, ISO_DATE).endOf("isoWeek").format(ISO_DATE)
}

export function monthRange(monthDateISO: string): {startDate: string; endDate: string} {
  const m = dayjs(monthDateISO, ISO_DATE)
  return {
    startDate: m.startOf("month").startOf("isoWeek").format(ISO_DATE),
    endDate: m.endOf("month").endOf("isoWeek").format(ISO_DATE),
  }
}

// Inclusive Mon-Sun range for the ISO week containing the date.
export function weekRange(dateISO: string): {startDate: string; endDate: string} {
  return {
    startDate: startOfIsoWeek(dateISO),
    endDate: endOfIsoWeek(dateISO),
  }
}

// Seven Mon-Sun day ISO dates for the week containing the date.
export function weekDays(dateISO: string): string[] {
  const start = dayjs(dateISO, ISO_DATE).startOf("isoWeek")
  return Array.from({length: 7}, (_, i) => start.add(i, "day").format(ISO_DATE))
}

export function businessDaysInMonth(monthDateISO: string): number {
  const start = dayjs(monthDateISO, ISO_DATE).startOf("month")
  const end = start.endOf("month")
  let count = 0
  let cur = start
  while (cur.isBefore(end) || cur.isSame(end, "day")) {
    if (cur.isoWeekday() < 6) count++
    cur = cur.add(1, "day")
  }
  return count
}

export function isStartable(dateISO: string): boolean {
  return (
    dayjs(dateISO, ISO_DATE).isSame(dayjs(), "day") ||
    dayjs(dateISO, ISO_DATE).isAfter(dayjs(), "day")
  )
}

// "01:30" -> 1.5; "1.5" -> 1.5; "" / invalid -> 0
export function parseHHMM(text: string): number {
  if (!text) return 0
  const trimmed = text.trim()
  if (trimmed.includes(":")) {
    const [h, m] = trimmed.split(":")
    const hours = parseInt(h, 10) || 0
    const minutes = parseInt(m, 10) || 0
    return hours + minutes / 60
  }
  const n = parseFloat(trimmed.replace(",", "."))
  return Number.isFinite(n) ? n : 0
}

// Matches the legacy `toHours` Angular filter at
// `app/assets/javascripts/angular/base/filters/time.coffee`:
// hours are NOT zero-padded, minutes are. e.g. 7.75 → "7:45".
export function formatHHMM(hours: number): string {
  if (!Number.isFinite(hours) || hours < 0) return "0:00"
  const totalMinutes = Math.round(hours * 60)
  const h = Math.floor(totalMinutes / 60)
  const m = totalMinutes % 60
  return `${h}:${String(m).padStart(2, "0")}`
}

// Live duration display for a running timer:
// elapsed = (now - startedAt) + storedValueHours
export function runningDuration(
  startedAtISO: string,
  storedValueHours: number,
  nowMs: number,
): string {
  const startedMs = Date.parse(startedAtISO)
  if (!Number.isFinite(startedMs)) return formatHHMM(storedValueHours)
  const elapsedHours = (nowMs - startedMs) / 3600000 + storedValueHours
  return formatHHMM(elapsedHours)
}

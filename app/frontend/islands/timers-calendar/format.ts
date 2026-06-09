import dayjs, {Dayjs} from "dayjs"
import isoWeek from "dayjs/plugin/isoWeek"
import customParseFormat from "dayjs/plugin/customParseFormat"

dayjs.extend(isoWeek)
dayjs.extend(customParseFormat)

const ISO_DATE = "YYYY-MM-DD"

export interface DayCell {
  date: string
  day: string
  dayOfWeek: number
  isCurrentMonth: boolean
  isCurrentDay: boolean
  isWeekend: boolean
}

export interface Week {
  days: DayCell[]
}

export function todayISO(): string {
  return dayjs().format(ISO_DATE)
}

export function startOfMonth(dateISO: string): string {
  return dayjs(dateISO, ISO_DATE).startOf("month").format(ISO_DATE)
}

export function addMonths(dateISO: string, n: number): string {
  return dayjs(dateISO, ISO_DATE).add(n, "month").format(ISO_DATE)
}

export function monthRange(monthDateISO: string): {startDate: string; endDate: string} {
  const m = dayjs(monthDateISO, ISO_DATE)
  return {
    startDate: m.startOf("month").startOf("isoWeek").format(ISO_DATE),
    endDate: m.endOf("month").endOf("isoWeek").format(ISO_DATE),
  }
}

export function buildWeeks(monthDateISO: string): Week[] {
  const today = todayISO()
  const month = dayjs(monthDateISO, ISO_DATE).format("YYYY-MM")
  let cursor: Dayjs = dayjs(monthDateISO, ISO_DATE).startOf("month").startOf("isoWeek")
  const end = dayjs(monthDateISO, ISO_DATE).endOf("month").endOf("isoWeek")
  const weeks: Week[] = []
  while (cursor.isBefore(end) || cursor.isSame(end, "day")) {
    const days: DayCell[] = []
    for (let i = 0; i < 7; i++) {
      const date = cursor.format(ISO_DATE)
      const dow = cursor.isoWeekday()
      days.push({
        date,
        day: cursor.format("D"),
        dayOfWeek: dow,
        isCurrentMonth: cursor.format("YYYY-MM") === month,
        isCurrentDay: date === today,
        isWeekend: dow >= 6,
      })
      cursor = cursor.add(1, "day")
    }
    weeks.push({days})
  }
  return weeks
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

export function monthLabel(monthDateISO: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, {month: "long", year: "numeric"}).format(
    dayjs(monthDateISO, ISO_DATE).toDate(),
  )
}

export function isStartable(dateISO: string): boolean {
  return dayjs(dateISO, ISO_DATE).isSame(dayjs(), "day") ||
    dayjs(dateISO, ISO_DATE).isAfter(dayjs(), "day")
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
export function runningDuration(startedAtISO: string, storedValueHours: number, nowMs: number): string {
  const startedMs = Date.parse(startedAtISO)
  if (!Number.isFinite(startedMs)) return formatHHMM(storedValueHours)
  const elapsedHours = (nowMs - startedMs) / 3600000 + storedValueHours
  return formatHHMM(elapsedHours)
}

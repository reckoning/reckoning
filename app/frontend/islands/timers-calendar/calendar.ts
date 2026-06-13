// Calendar-grid-specific layout helpers for the timers-calendar
// island. Shared time/date utilities live in `lib/timers/format.ts`.

import dayjs, {Dayjs} from "dayjs"
import isoWeek from "dayjs/plugin/isoWeek"
import customParseFormat from "dayjs/plugin/customParseFormat"
import {todayISO, ISO_DATE} from "../../lib/timers/format"

dayjs.extend(isoWeek)
dayjs.extend(customParseFormat)

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

export function monthLabel(monthDateISO: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, {month: "long", year: "numeric"}).format(
    dayjs(monthDateISO, ISO_DATE).toDate(),
  )
}

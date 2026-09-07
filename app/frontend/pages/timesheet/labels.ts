// Weekday and month names for the timesheet, from Intl rather than from the
// twelve strings Rails used to hand the island.
//
// Both anchor on UTC midnights, so both format in UTC: west of Greenwich a
// UTC midnight belongs to the previous local day, which would label Monday as
// Sunday and January as December.

// 2024-01-01 was a Monday, so seven days from there is one ISO week in the
// order the grid renders it.
export function weekdayNames(locale: string, width: "short" | "long"): string[] {
  const format = new Intl.DateTimeFormat(locale, {weekday: width, timeZone: "UTC"})

  return Array.from({length: 7}, (_, index) => format.format(new Date(Date.UTC(2024, 0, 1 + index))))
}

export function monthNames(locale: string): string[] {
  const format = new Intl.DateTimeFormat(locale, {month: "long", timeZone: "UTC"})

  return Array.from({length: 12}, (_, index) => format.format(new Date(Date.UTC(2024, index, 1))))
}

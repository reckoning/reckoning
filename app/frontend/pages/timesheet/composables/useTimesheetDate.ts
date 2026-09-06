import {computed} from "vue"
import {useRoute, useRouter} from "vue-router"
import {todayISO, addDays, startOfIsoWeek, ISO_DATE} from "@/lib/timers/format"
import dayjs from "dayjs"

const DATE_KEY = "date"
const VIEW_KEY = "view"

export type TimesheetView = "day" | "week"

// Date + view state synced to the URL query string.
//
//   /app/timesheet?date=2026-06-12&view=day
//   /app/timesheet?date=2026-06-12&view=week
//
// The query *is* the state, so the back button steps through previous
// days and weeks the way the AngularJS hash route did. As an island this
// wrote history entries itself; inside the SPA that would go behind the
// router's back, so it pushes routes instead.
export function useTimesheetDate() {
  const route = useRoute()
  const router = useRouter()

  const date = computed<string>(() => {
    const raw = route.query[DATE_KEY]

    return typeof raw === "string" && /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : todayISO()
  })

  const view = computed<TimesheetView>(() => (route.query[VIEW_KEY] === "week" ? "week" : "day"))

  function setDate(next: string) {
    if (next === date.value) return

    router.push({query: {...route.query, [DATE_KEY]: next, [VIEW_KEY]: view.value}})
  }

  function setView(next: TimesheetView) {
    if (next === view.value) return

    router.push({query: {...route.query, [DATE_KEY]: date.value, [VIEW_KEY]: next}})
  }

  function prev() {
    setDate(addDays(date.value, view.value === "week" ? -7 : -1))
  }

  function next() {
    setDate(addDays(date.value, view.value === "week" ? 7 : 1))
  }

  function today() {
    setDate(todayISO())
  }

  function jump(ymd: string) {
    setDate(ymd)
  }

  const weekStart = computed(() => startOfIsoWeek(date.value))
  const isToday = computed(() => {
    if (view.value === "day") return date.value === todayISO()
    return weekStart.value === startOfIsoWeek(todayISO())
  })
  const monthIndex = computed(() => dayjs(date.value, ISO_DATE).month())
  const year = computed(() => dayjs(date.value, ISO_DATE).year())

  return {date, view, weekStart, isToday, monthIndex, year, setDate, setView, prev, next, today, jump}
}

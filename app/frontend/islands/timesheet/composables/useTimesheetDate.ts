import {ref, computed, onMounted, onBeforeUnmount} from "vue"
import {todayISO, addDays, startOfIsoWeek, ISO_DATE} from "../../../lib/timers/format"
import dayjs from "dayjs"

const DATE_KEY = "date"
const VIEW_KEY = "view"

export type TimesheetView = "day" | "week"

function readFromUrl(): {date: string; view: TimesheetView} {
  const params = new URLSearchParams(window.location.search)
  const dateRaw = params.get(DATE_KEY)
  const viewRaw = params.get(VIEW_KEY)
  const date = dateRaw && /^\d{4}-\d{2}-\d{2}$/.test(dateRaw) ? dateRaw : todayISO()
  const view: TimesheetView = viewRaw === "week" ? "week" : "day"
  return {date, view}
}

// Date + view state synced to the URL query string.
//
//   /timesheet?date=2026-06-12&view=day
//   /timesheet?date=2026-06-12&view=week
//
// `pushState` (not Turbo.visit) so the browser back button steps
// through previous days/weeks the same way the legacy AngularJS
// hash route did (`#/day/...` / `#/week/...`).
export function useTimesheetDate() {
  const initial = readFromUrl()
  const date = ref<string>(initial.date)
  const view = ref<TimesheetView>(initial.view)

  function writeUrl() {
    const url = new URL(window.location.href)
    url.searchParams.set(DATE_KEY, date.value)
    url.searchParams.set(VIEW_KEY, view.value)
    window.history.pushState({}, "", url.toString())
  }

  function setDate(next: string) {
    if (next === date.value) return
    date.value = next
    writeUrl()
  }

  function setView(next: TimesheetView) {
    if (next === view.value) return
    view.value = next
    writeUrl()
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

  const onPopState = () => {
    const {date: d, view: v} = readFromUrl()
    date.value = d
    view.value = v
  }
  onMounted(() => window.addEventListener("popstate", onPopState))
  onBeforeUnmount(() => window.removeEventListener("popstate", onPopState))

  const weekStart = computed(() => startOfIsoWeek(date.value))
  const isToday = computed(() => {
    if (view.value === "day") return date.value === todayISO()
    return weekStart.value === startOfIsoWeek(todayISO())
  })
  const monthIndex = computed(() => dayjs(date.value, ISO_DATE).month())
  const year = computed(() => dayjs(date.value, ISO_DATE).year())

  return {date, view, weekStart, isToday, monthIndex, year, setDate, setView, prev, next, today, jump}
}

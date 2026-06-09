import {ref, onMounted, onBeforeUnmount} from "vue"
import {startOfMonth, todayISO, addMonths} from "../format"

const QUERY_KEY = "month"

function readFromUrl(): string {
  const params = new URLSearchParams(window.location.search)
  const raw = params.get(QUERY_KEY)
  if (raw && /^\d{4}-\d{2}-\d{2}$/.test(raw)) return startOfMonth(raw)
  return startOfMonth(todayISO())
}

// Month state synced to `?month=YYYY-MM-DD` on the current URL.
// Uses pushState so the browser back button steps through months
// — the legacy AngularJS calendar behaves the same way (hash route).
// Skips Turbo on purpose: we're mutating only the query string, not
// navigating to a new Rails page.
export function useMonth() {
  const month = ref<string>(readFromUrl())

  const writeUrl = (value: string) => {
    const url = new URL(window.location.href)
    url.searchParams.set(QUERY_KEY, value)
    window.history.pushState({}, "", url.toString())
  }

  const set = (value: string) => {
    const normalized = startOfMonth(value)
    if (normalized === month.value) return
    month.value = normalized
    writeUrl(normalized)
  }

  const next = () => set(addMonths(month.value, 1))
  const prev = () => set(addMonths(month.value, -1))
  const today = () => set(startOfMonth(todayISO()))

  const onPopState = () => {
    month.value = readFromUrl()
  }

  onMounted(() => window.addEventListener("popstate", onPopState))
  onBeforeUnmount(() => window.removeEventListener("popstate", onPopState))

  return {month, set, next, prev, today}
}

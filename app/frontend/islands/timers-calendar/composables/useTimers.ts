import {ref, watch, onBeforeUnmount, type Ref} from "vue"
import {createConsumer, type Consumer, type Subscription} from "@rails/actioncable"
import {listTimers} from "../api"
import {monthRange} from "../format"
import type {Timer} from "../types"

let consumer: Consumer | null = null
function cable(): Consumer {
  if (!consumer) consumer = createConsumer()
  return consumer
}

// Reactive timers for the given project + month. Re-fetches on
// month change, and merges live updates from TimersChannel so
// changes in other tabs / from `/timesheet` show up immediately.
//
// `TimersChannel#subscribed` streams from
// `timers_<userId>_<room>`; the room `"all"` catches every date,
// which is what we want because a calendar tab spans a full month.
// Server-side, `Api::V1::TimersController#send_realtime_update`
// always also broadcasts to the `all` room — see that controller.
export function useTimers(projectId: string, month: Ref<string>) {
  const timers = ref<Timer[]>([])
  const loading = ref(false)
  const error = ref<unknown>(null)

  let abortToken = 0

  async function refresh() {
    const token = ++abortToken
    loading.value = true
    error.value = null
    try {
      const {startDate, endDate} = monthRange(month.value)
      const fetched = await listTimers({projectId, startDate, endDate})
      if (token === abortToken) timers.value = fetched
    } catch (e) {
      if (token === abortToken) error.value = e
    } finally {
      if (token === abortToken) loading.value = false
    }
  }

  // Merge an incoming timer broadcast into the local list.
  // The server includes `deleted: true` on the destroy payload,
  // and may include timers from other projects (the channel is
  // user-scoped, not project-scoped) — filter both here.
  function applyCableUpdate(payload: Timer) {
    if (payload.projectId !== projectId) return
    if (payload.deleted) {
      timers.value = timers.value.filter((t) => t.id !== payload.id)
      return
    }
    const {startDate, endDate} = monthRange(month.value)
    const inRange = payload.date >= startDate && payload.date <= endDate
    const idx = timers.value.findIndex((t) => t.id === payload.id)
    if (idx >= 0) {
      if (inRange) timers.value.splice(idx, 1, payload)
      else timers.value.splice(idx, 1)
    } else if (inRange) {
      timers.value.push(payload)
    }
  }

  let subscription: Subscription | null = null
  function subscribe() {
    subscription?.unsubscribe()
    subscription = cable().subscriptions.create(
      {channel: "TimersChannel", room: "all"},
      {
        received(raw: unknown) {
          // Server broadcasts the raw jbuilder string; in newer
          // ActionCable client versions it's auto-parsed to an
          // object, but accept both for safety. Decimal fields
          // come back stringified (same as listTimers) so coerce.
          const parsed = typeof raw === "string" ? JSON.parse(raw) : raw
          const data = parsed as Timer & {value: unknown; sumForTask: unknown}
          applyCableUpdate({
            ...data,
            value: typeof data.value === "string" ? parseFloat(data.value) : data.value,
            sumForTask:
              typeof data.sumForTask === "string" ? parseFloat(data.sumForTask) : data.sumForTask,
          } as Timer)
        },
      },
    )
  }

  watch(month, refresh, {immediate: true})
  subscribe()

  onBeforeUnmount(() => {
    abortToken++
    subscription?.unsubscribe()
    subscription = null
  })

  return {timers, loading, error, refresh}
}

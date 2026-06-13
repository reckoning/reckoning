import {ref, watch, onBeforeUnmount, type Ref} from "vue"
import {createConsumer, type Consumer, type Subscription} from "@rails/actioncable"
import {listTimers} from "../../../lib/timers/api"
import type {Timer} from "../../../lib/timers/types"

let consumer: Consumer | null = null
function cable(): Consumer {
  if (!consumer) consumer = createConsumer()
  return consumer
}

// Reactive timers for the given day, plus live ActionCable
// updates from other tabs / from the timers-calendar island.
// Subscribes with `room: "all"` (same as the calendar) so any
// timer change for the user flows back; we filter by date here.
export function useDayTimers(date: Ref<string>) {
  const timers = ref<Timer[]>([])
  const loading = ref(false)
  const error = ref<unknown>(null)

  let token = 0

  async function refresh() {
    const t = ++token
    loading.value = true
    error.value = null
    try {
      const fetched = await listTimers({date: date.value})
      if (t === token) timers.value = fetched
    } catch (e) {
      if (t === token) error.value = e
    } finally {
      if (t === token) loading.value = false
    }
  }

  function applyCableUpdate(payload: Timer) {
    if (payload.deleted) {
      timers.value = timers.value.filter((t) => t.id !== payload.id)
      return
    }
    if (payload.date !== date.value) {
      // Timer was edited to a different date — remove if it was
      // shown here previously.
      timers.value = timers.value.filter((t) => t.id !== payload.id)
      return
    }
    const idx = timers.value.findIndex((t) => t.id === payload.id)
    if (idx >= 0) timers.value.splice(idx, 1, payload)
    else timers.value.push(payload)
  }

  let subscription: Subscription | null = null
  function subscribe() {
    subscription?.unsubscribe()
    subscription = cable().subscriptions.create(
      {channel: "TimersChannel", room: "all"},
      {
        received(raw: unknown) {
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

  watch(date, refresh, {immediate: true})
  subscribe()

  onBeforeUnmount(() => {
    token++
    subscription?.unsubscribe()
    subscription = null
  })

  return {timers, loading, error, refresh}
}

import {ref, watch, onBeforeUnmount, type Ref} from "vue"
import {listTasks, type TaskWithTimers} from "../../../lib/timers/api"

// Reactive tasks for the ISO week containing `weekDate`. Each
// task includes its own `timers` array for the week (per the
// `/api/v1/tasks?weekDate=...` shape).
//
// No ActionCable here — the week view's cell-blur autosave is the
// only mutation path, and after each save we either re-fetch (on
// success) or roll back the field. Cross-tab sync via cable is
// out of scope for the MVP (the calendar covers the project-show
// case).
export function useWeekTasks(weekDate: Ref<string>) {
  const tasks = ref<TaskWithTimers[]>([])
  const loading = ref(false)
  const error = ref<unknown>(null)

  let token = 0

  async function refresh() {
    const t = ++token
    loading.value = true
    error.value = null
    try {
      const fetched = await listTasks({weekDate: weekDate.value})
      if (t === token) tasks.value = fetched
    } catch (e) {
      if (t === token) error.value = e
    } finally {
      if (t === token) loading.value = false
    }
  }

  watch(weekDate, refresh, {immediate: true})

  onBeforeUnmount(() => {
    token++
  })

  return {tasks, loading, error, refresh}
}

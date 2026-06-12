import type { Project, Timer, TimerPayload } from "./types"

interface AppGlobals {
  ApiBasePath?: string
  ApiHeaders?: Headers
}

const win = window as unknown as AppGlobals

function basePath(): string {
  return win.ApiBasePath ?? ""
}

function headers(): Headers {
  // ApiHeaders is set by `app/views/layouts/_js_defaults.html.erb`
  // on every page load — Bearer token + Content-Type. Fall back to
  // a plain JSON header so type checks pass on the (unreachable)
  // path where it's missing.
  return win.ApiHeaders ?? new Headers({"Content-Type": "application/json"})
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(`${basePath()}${path}`, {headers: headers(), ...init})
  if (!res.ok) {
    let detail: unknown
    try {
      detail = await res.json()
    } catch {
      detail = await res.text()
    }
    throw new ApiError(res.status, detail)
  }
  if (res.status === 204) return undefined as T
  return (await res.json()) as T
}

// Rails decimal columns (timer.value, sum_for_task) serialize as
// strings — `"7.0"` rather than `7.0` — so coerce at the boundary
// to keep the rest of the island working with real numbers.
function toNumber(v: unknown): number {
  if (typeof v === "number") return v
  if (typeof v === "string") {
    const n = parseFloat(v)
    return Number.isFinite(n) ? n : 0
  }
  return 0
}

function normalizeTimer(raw: Timer): Timer {
  return {
    ...raw,
    value: toNumber(raw.value),
    sumForTask: toNumber(raw.sumForTask),
    startTime: raw.startTime == null ? null : toNumber(raw.startTime),
    startTimeForTask: raw.startTimeForTask == null ? null : toNumber(raw.startTimeForTask),
  }
}

export class ApiError extends Error {
  constructor(public status: number, public detail: unknown) {
    super(`API request failed (${status})`)
  }
}

// `listTimers` accepts either a single `date` (day view) or a
// `startDate`/`endDate` range (calendar month, week). `projectId`
// is optional — omit it on the timesheet which is scoped per-user
// across all projects.
export async function listTimers(params: {
  projectId?: string
  date?: string
  startDate?: string
  endDate?: string
}): Promise<Timer[]> {
  const qs = new URLSearchParams()
  if (params.projectId) qs.set("projectId", params.projectId)
  if (params.date) qs.set("date", params.date)
  if (params.startDate) qs.set("startDate", params.startDate)
  if (params.endDate) qs.set("endDate", params.endDate)
  const raw = await request<Timer[]>(`/api/v1/timers?${qs.toString()}`)
  return raw.map(normalizeTimer)
}

export function listProjects(): Promise<Project[]> {
  return request<Project[]>(`/api/v1/projects?sort=used`)
}

// Tasks the user has touched in the ISO week containing
// `weekDate`. Used by the timesheet's week view to build the
// grid of task rows. Each task includes its `timers` for the week.
export async function listTasks(params: {weekDate: string}): Promise<TaskWithTimers[]> {
  const qs = new URLSearchParams({weekDate: params.weekDate})
  const raw = await request<TaskWithTimers[]>(`/api/v1/tasks?${qs.toString()}`)
  return raw.map((t) => ({...t, timers: t.timers.map(normalizeTimer)}))
}

export type TaskWithTimers = {
  id: string
  name: string
  label: string
  billable: boolean
  projectId: string
  projectName: string
  projectCustomerName: string | null
  timers: Timer[]
  createdAt: string
  updatedAt: string
}

export async function createTimer(payload: TimerPayload, started: boolean): Promise<Timer> {
  return normalizeTimer(
    await request<Timer>(`/api/v1/timers`, {
      method: "POST",
      body: JSON.stringify({...payload, started}),
    }),
  )
}

export async function updateTimer(
  id: string,
  payload: TimerPayload,
  started: boolean,
): Promise<Timer> {
  return normalizeTimer(
    await request<Timer>(`/api/v1/timers/${id}`, {
      method: "PUT",
      body: JSON.stringify({...payload, started}),
    }),
  )
}

export async function startTimer(id: string): Promise<Timer> {
  return normalizeTimer(await request<Timer>(`/api/v1/timers/${id}/start`, {method: "PUT"}))
}

export async function stopTimer(id: string): Promise<Timer> {
  return normalizeTimer(await request<Timer>(`/api/v1/timers/${id}/stop`, {method: "PUT"}))
}

export function deleteTimer(id: string): Promise<void> {
  return request<void>(`/api/v1/timers/${id}`, {method: "DELETE"})
}

export function createTask(payload: {projectId: string; name: string}) {
  return request<{id: string; name: string; label: string; billable: boolean; projectId: string}>(
    `/api/v1/tasks`,
    {method: "POST", body: JSON.stringify(payload)},
  )
}

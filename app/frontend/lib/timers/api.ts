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

export async function listTimers(params: {
  projectId: string
  startDate: string
  endDate: string
}): Promise<Timer[]> {
  const qs = new URLSearchParams({
    projectId: params.projectId,
    startDate: params.startDate,
    endDate: params.endDate,
  })
  const raw = await request<Timer[]>(`/api/v1/timers?${qs.toString()}`)
  return raw.map(normalizeTimer)
}

export function listProjects(): Promise<Project[]> {
  return request<Project[]>(`/api/v1/projects?sort=used`)
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

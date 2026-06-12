// Wire types for the timers-calendar island.
//
// Keys are camelCase because the Rails API stack rewrites JSON on
// both sides: `config/initializers/jbuilder.rb` sets
// `Jbuilder.key_format camelize: :lower` (responses) and
// `config/initializers/json_param_key_transform.rb` underscores
// request keys (requests). So `_show.json.jbuilder` writing
// `task_billable` lands on the wire as `taskBillable`.

export interface Timer {
  id: string
  date: string
  value: number
  note: string | null
  sumForTask: number
  started: boolean
  startedAt: string | null
  startTime: number | null
  startTimeForTask: number | null
  positionId: string | null
  invoiced: boolean
  taskId: string
  taskName: string
  taskLabel: string
  taskBillable: boolean
  projectId: string
  projectName: string
  projectCustomerName: string | null
  createdAt: string
  updatedAt: string
  deleted: boolean
  links: { project: { href: string } }
}

export interface Task {
  id: string
  name: string
  label: string
  billable: boolean
  projectId: string
  createdAt: string
  updatedAt: string
}

export interface Project {
  id: string
  name: string
  customerName: string | null
  label: string
  tasks: Task[]
  createdAt: string
  updatedAt: string
}

export type TimerPayload = {
  date: string
  value: number
  note: string | null
  taskId: string
}

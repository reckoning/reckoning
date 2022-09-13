/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Task } from './Task'

export type Project = {
  id?: string
  name?: string
  customerName?: string
  label?: string
  tasks?: Array<Task>
  createdAt?: string
  updatedAt?: string
  links?: {
    show?: {
      href?: string
    }
  }
}

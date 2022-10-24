/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { ProjectMinimal } from "./ProjectMinimal";
import type { Task } from "./Task";

export type Timer = {
  id: string;
  date: string;
  value: number;
  note?: string;
  started?: boolean;
  startedAt?: string;
  startTime?: string;
  startTimeForTask?: null;
  positionId?: string;
  invoiced?: boolean;
  project: ProjectMinimal;
  task: Task;
  createdAt: string;
  updatedAt: string;
  deleted?: boolean;
  links?: {
    project?: {
      href?: string;
    };
  };
};

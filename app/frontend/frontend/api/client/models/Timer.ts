/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

export type Timer = {
  id: string;
  date: string;
  value?: string;
  sumForTask?: string;
  note?: string;
  started?: boolean;
  startedAt?: string;
  startTime?: string;
  startTimeForTask?: null;
  positionId?: string;
  invoiced?: boolean;
  taskId: string;
  taskName?: string;
  taskLabel?: string;
  taskBillable?: boolean;
  projectId: string;
  projectName?: string;
  projectCustomerName?: string;
  createdAt: string;
  updatedAt: string;
  deleted?: boolean;
  links?: {
    project?: {
      href?: string;
    };
  };
};

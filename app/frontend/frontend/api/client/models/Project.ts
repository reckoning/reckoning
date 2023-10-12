/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Task } from "./Task";

export type Project = {
  id?: string;
  name?: string;
  label?: string;
  customerName?: string;
  customerId?: string;
  timerValues?: number;
  timerValuesBillable?: number;
  timerValuesInvoiced?: number;
  timerValuesUninvoiced?: number;
  invoiceValues?: number;
  rate?: number;
  budget?: number;
  budgetOnDashboard?: boolean;
  budgetHours?: number;
  budgetPercent?: number;
  budgetPercentInvoiced?: number;
  budgetPercentUninvoiced?: number;
  roundUp?: number;
  state?: string;
  federalState?: string;
  businessDays?: number;
  startDate?: string;
  endDate?: string;
  tasks?: Array<Task>;
  createdAt?: string;
  updatedAt?: string;
  links?: {
    show?: {
      href?: string;
    };
  };
};

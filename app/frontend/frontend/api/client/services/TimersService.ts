/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Timer } from "../models/Timer";
import type { TimerInput } from "../models/TimerInput";

import type { CancelablePromise } from "../core/CancelablePromise";
import type { BaseHttpRequest } from "../core/BaseHttpRequest";

export class TimersService {
  constructor(public readonly httpRequest: BaseHttpRequest) {}

  /**
   * Timers Index
   * List of Timers
   * @returns Timer OK
   * @throws ApiError
   */
  public getTimers({
    date,
    weekDate,
  }: {
    /**
     * Filter by Date
     */
    date?: string;
    /**
     * Filter by Week
     */
    weekDate?: string;
  }): CancelablePromise<Array<Timer>> {
    return this.httpRequest.request({
      method: "GET",
      url: "/timers",
      query: {
        date: date,
        weekDate: weekDate,
      },
    });
  }

  /**
   * Create Timer
   * Create a new Timer
   * @returns Timer Created
   * @throws ApiError
   */
  public createTimer({
    requestBody,
  }: {
    requestBody?: TimerInput;
  }): CancelablePromise<Timer> {
    return this.httpRequest.request({
      method: "POST",
      url: "/timers",
      body: requestBody,
      mediaType: "application/json",
    });
  }

  /**
   * Start Timer
   * Start a Timer
   * @returns Timer OK
   * @throws ApiError
   */
  public startTimer({
    id,
  }: {
    /**
     * Timer ID
     */
    id: string;
  }): CancelablePromise<Timer> {
    return this.httpRequest.request({
      method: "PUT",
      url: "/timers/{id}/start",
      path: {
        id: id,
      },
      errors: {
        400: `Bad Request`,
      },
    });
  }

  /**
   * Stop Timer
   * Stop a Timer
   * @returns Timer OK
   * @throws ApiError
   */
  public stopTimer({
    id,
  }: {
    /**
     * Timer ID
     */
    id: string;
  }): CancelablePromise<Timer> {
    return this.httpRequest.request({
      method: "PUT",
      url: "/timers/{id}/stop",
      path: {
        id: id,
      },
      errors: {
        400: `Bad Request`,
      },
    });
  }
}

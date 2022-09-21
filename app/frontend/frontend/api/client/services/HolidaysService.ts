/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { GermanHoliday } from "../models/GermanHoliday";

import type { CancelablePromise } from "../core/CancelablePromise";
import type { BaseHttpRequest } from "../core/BaseHttpRequest";

export class HolidaysService {
  constructor(public readonly httpRequest: BaseHttpRequest) {}

  /**
   * German Holidays Index
   * List of German Holidays
   * @returns GermanHoliday OK
   * @throws ApiError
   */
  public getGermanHolidays({
    year,
    state,
  }: {
    /**
     * Year
     */
    year?: number;
    /**
     * Federal State Shorthand
     */
    state?: any[];
  }): CancelablePromise<Array<GermanHoliday>> {
    return this.httpRequest.request({
      method: "GET",
      url: "/german-holidays",
      query: {
        year: year,
        state: state,
      },
    });
  }
}

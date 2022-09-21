/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Customer } from "../models/Customer";

import type { CancelablePromise } from "../core/CancelablePromise";
import type { BaseHttpRequest } from "../core/BaseHttpRequest";

export class CustomersService {
  constructor(public readonly httpRequest: BaseHttpRequest) {}

  /**
   * Customers Index
   * List of Customers
   * @returns Customer OK
   * @throws ApiError
   */
  public getCustomers(): CancelablePromise<Array<Customer>> {
    return this.httpRequest.request({
      method: "GET",
      url: "/customers",
    });
  }

  /**
   * Customer Detail
   * Customer Detail
   * @returns Customer OK
   * @throws ApiError
   */
  public getCustomersId({
    id,
  }: {
    /**
     * Customer ID
     */
    id: string;
  }): CancelablePromise<Customer> {
    return this.httpRequest.request({
      method: "GET",
      url: "/customers/{id}",
      path: {
        id: id,
      },
    });
  }
}

/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { SessionForm } from "../models/SessionForm";

import type { CancelablePromise } from "../core/CancelablePromise";
import type { BaseHttpRequest } from "../core/BaseHttpRequest";

export class SessionsService {
  constructor(public readonly httpRequest: BaseHttpRequest) {}

  /**
   * Create Session
   * Create new Session
   * @returns string Successfully authenticated. The session ID is returned in a cookie named `RECKONING`. You need to include this cookie in subsequent requests.
   *
   * @throws ApiError
   */
  public createSession({
    requestBody,
  }: {
    requestBody?: SessionForm;
  }): CancelablePromise<string> {
    return this.httpRequest.request({
      method: "POST",
      url: "/sessions",
      body: requestBody,
      mediaType: "application/json",
      responseHeader: "Set-Cookie",
      errors: {
        400: `Bad Request`,
      },
    });
  }

  /**
   * Destroy Session
   * Destroy the current Session
   * @returns any OK
   * @throws ApiError
   */
  public deleteSession(): CancelablePromise<any> {
    return this.httpRequest.request({
      method: "DELETE",
      url: "/sessions",
    });
  }
}

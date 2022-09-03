/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { User } from '../models/User'

import type { CancelablePromise } from '../core/CancelablePromise'
import type { BaseHttpRequest } from '../core/BaseHttpRequest'

export class UsersService {
  constructor(public readonly httpRequest: BaseHttpRequest) {}

  /**
   * Get current User
   * Get current User
   * @returns User OK
   * @throws ApiError
   */
  public getMe(): CancelablePromise<User> {
    return this.httpRequest.request({
      method: 'GET',
      url: '/me',
    })
  }
}

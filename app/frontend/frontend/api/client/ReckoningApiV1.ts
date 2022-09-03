/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from './core/BaseHttpRequest'
import type { OpenAPIConfig } from './core/OpenAPI'
import { AxiosHttpRequest } from './core/AxiosHttpRequest'

import { SessionsService } from './services/SessionsService'
import { UsersService } from './services/UsersService'

type HttpRequestConstructor = new (config: OpenAPIConfig) => BaseHttpRequest

export class ReckoningApiV1 {
  public readonly sessions: SessionsService
  public readonly users: UsersService

  public readonly request: BaseHttpRequest

  constructor(
    config?: Partial<OpenAPIConfig>,
    HttpRequest: HttpRequestConstructor = AxiosHttpRequest
  ) {
    this.request = new HttpRequest({
      BASE: config?.BASE ?? 'http://reckoning.test/api/v1',
      VERSION: config?.VERSION ?? '1.0',
      WITH_CREDENTIALS: config?.WITH_CREDENTIALS ?? false,
      CREDENTIALS: config?.CREDENTIALS ?? 'include',
      TOKEN: config?.TOKEN,
      USERNAME: config?.USERNAME,
      PASSWORD: config?.PASSWORD,
      HEADERS: config?.HEADERS,
      ENCODE_PATH: config?.ENCODE_PATH,
    })

    this.sessions = new SessionsService(this.request)
    this.users = new UsersService(this.request)
  }
}

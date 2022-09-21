/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Project } from "../models/Project";

import type { CancelablePromise } from "../core/CancelablePromise";
import type { BaseHttpRequest } from "../core/BaseHttpRequest";

export class ProjectsService {
  constructor(public readonly httpRequest: BaseHttpRequest) {}

  /**
   * Projects Index
   * List of Projects
   * @returns Project OK
   * @throws ApiError
   */
  public getProjects(): CancelablePromise<Array<Project>> {
    return this.httpRequest.request({
      method: "GET",
      url: "/projects",
    });
  }

  /**
   * Project Detail
   * Project Detail
   * @returns Project OK
   * @throws ApiError
   */
  public getProject({
    id,
  }: {
    /**
     * Id of Project
     */
    id: string;
  }): CancelablePromise<Project> {
    return this.httpRequest.request({
      method: "GET",
      url: "/projects/{id}",
      path: {
        id: id,
      },
    });
  }
}

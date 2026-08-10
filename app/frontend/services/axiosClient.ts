import Axios, { type AxiosRequestConfig, type AxiosError } from "axios";
import Qs from "qs";

export const AXIOS_INSTANCE = Axios.create({
  baseURL: "/api/v1",
  withCredentials: true,
  paramsSerializer: (params) =>
    Qs.stringify(params, {
      arrayFormat: "brackets",
      encode: false,
    }),
});

export const axiosClient = <T>(config: AxiosRequestConfig): Promise<T> => {
  const source = Axios.CancelToken.source();

  const promise = AXIOS_INSTANCE({
    ...config,
    headers: {
      ...config.headers,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    cancelToken: source.token,
  }).then(({ data }) => data);

  // @ts-expect-error - vue-query calls .cancel() on the returned promise
  promise.cancel = () => {
    source.cancel("Query was cancelled by Vue Query");
  };

  return promise;
};

export type ErrorType<Error> = AxiosError<Error>;

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

// Api::BaseController runs `protect_from_forgery` for cookie-authenticated
// requests, so every mutation needs the token Rails put in the layout.
export function csrfToken(): string | undefined {
  return (
    document
      .querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
      ?.content ?? undefined
  );
}

const SAFE_METHODS = ["get", "head", "options"];

type UnauthorizedHandler = () => void;

let unauthorizedHandler: UnauthorizedHandler | undefined;

// The router is not reachable from here, so the app wires navigation in at
// boot. Without a handler an expired session would surface as a bare error on
// whichever screen happened to be open.
export function onUnauthorized(handler: UnauthorizedHandler): void {
  unauthorizedHandler = handler;
}

AXIOS_INSTANCE.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      unauthorizedHandler?.();
    }

    return Promise.reject(error);
  },
);

export const axiosClient = <T>(config: AxiosRequestConfig): Promise<T> => {
  const source = Axios.CancelToken.source();
  const method = config.method?.toLowerCase() ?? "get";
  const token = SAFE_METHODS.includes(method) ? undefined : csrfToken();

  const promise = AXIOS_INSTANCE({
    ...config,
    headers: {
      ...config.headers,
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { "X-CSRF-Token": token } : {}),
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

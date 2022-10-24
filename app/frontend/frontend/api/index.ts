import axios from "axios";
import type { AxiosError } from "axios";
import nprogress from "nprogress";
import { ReckoningApiV1 } from "@/frontend/api/client/ReckoningApiV1";
import useAuthStore from "@/frontend/stores/Auth";

const apiClient = new ReckoningApiV1({
  BASE: window.API_ENDPOINT,
  WITH_CREDENTIALS: true,
});

axios.interceptors.request.use(
  (config) => {
    nprogress.start();
    return config;
  },
  (error) => {
    nprogress.done();
    return Promise.reject(error);
  }
);

axios.interceptors.response.use(
  (response) => {
    nprogress.done();

    return response;
  },
  (error: AxiosError) => {
    nprogress.done();

    const authStore = useAuthStore();

    if (
      error.response &&
      error.response.status === 401 &&
      authStore.authenticated
    ) {
      authStore.logout();
    }

    return Promise.reject(error);
  }
);

export const { sessions } = apiClient;
export const { users } = apiClient;
export const { timers } = apiClient;

export default apiClient;

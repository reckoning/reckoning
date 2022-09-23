import axios from "axios";
import type { AxiosError } from "axios";
import { ReckoningApiV1 } from "@/frontend/api/client/ReckoningApiV1";
import useAuthStore from "@/frontend/stores/Auth";

const apiClient = new ReckoningApiV1({
  BASE: window.API_ENDPOINT,
  WITH_CREDENTIALS: true,
});

axios.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
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

export default apiClient;

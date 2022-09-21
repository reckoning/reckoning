import { createApp } from "vue";
import App from "@/frontend/App.vue";
import router from "@/frontend/lib/Router";
import pinia from "@/frontend/lib/Pinia";

declare global {
  interface Window {
    API_ENDPOINT: string;
    FRONTEND_BASE_URL: string;
  }
}

const app = createApp(App);

app.use(router);
app.use(pinia);

app.mount("#app");

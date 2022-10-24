import { createApp } from "vue";
import type { Component } from "vue";
import App from "@/frontend/App.vue";
import router from "@/frontend/lib/Router";
import pinia from "@/frontend/plugins/Pinia";
import cable from "@/frontend/plugins/Cable";

declare global {
  interface Window {
    API_ENDPOINT: string;
    CABLE_ENDPOINT: string;
    FRONTEND_BASE_URL: string;
  }
}

const app = createApp(App as Component);

app.use(router);
app.use(pinia);
app.use(cable);

app.mount("#app");

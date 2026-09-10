import { createApp } from "vue";
import { createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { errorHandler } from "@appsignal/vue";
import App from "@/App.vue";
import { router } from "@/plugins/router";
import { i18n } from "@/plugins/i18n";
import { onUnauthorized } from "@/services/axiosClient";
import { useCurrentUserStore } from "@/stores/currentUser";
import { useToastsStore } from "@/stores/toasts";
import { appsignal } from "@/lib/appsignal";

const mountPoint = document.getElementById("spa");

if (mountPoint) {
  const pinia = createPinia();
  pinia.use(piniaPluginPersistedstate);

  const app = createApp(App);

  if (appsignal) {
    app.config.errorHandler = errorHandler(appsignal, app);
  }

  app.use(pinia);
  app.use(i18n);
  app.use(VueQueryPlugin);
  app.use(router);

  // Pinia has to be installed before the store is reachable, so the 401 hook
  // is wired here rather than inside axiosClient.
  onUnauthorized(() => {
    const currentUser = useCurrentUserStore(pinia);
    currentUser.clear();

    if (router.currentRoute.value.name !== "login") {
      void router.replace({ name: "login" });
    }
  });

  // A refusal from what is left of the server-rendered app redirects here
  // with its reason in the flash, which the shell hands over on the mount
  // point. Shown as a toast, or the SPA would answer with a screen and no
  // explanation.
  const flash = useToastsStore(pinia);

  if (mountPoint.dataset.flashError) flash.push("error", mountPoint.dataset.flashError);
  if (mountPoint.dataset.flashSuccess) flash.push("success", mountPoint.dataset.flashSuccess);

  app.mount(mountPoint);
}

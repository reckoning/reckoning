import type { App } from "vue";
import { createCable } from "@anycable/web";

export default {
  install: (app: App) => {
    const $cable = createCable(window.CABLE_ENDPOINT);

    app.provide("$cable", $cable);
  },
};

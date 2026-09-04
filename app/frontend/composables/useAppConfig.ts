import { ref } from "vue";
import { appConfig } from "@/services/api/services/config/config";
import type { AppConfig } from "@/services/api/models";

// Module-level so the shell asks once, not once per screen that needs it.
const config = ref<AppConfig | undefined>();
let inFlight: Promise<AppConfig | undefined> | undefined;

export function useAppConfig() {
  if (!config.value && !inFlight) {
    inFlight = appConfig()
      .then((loaded) => {
        config.value = loaded;
        return loaded;
      })
      .catch(() => undefined)
      .finally(() => {
        inFlight = undefined;
      });
  }

  return { config, ready: inFlight ?? Promise.resolve(config.value) };
}

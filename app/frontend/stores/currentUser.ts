import { defineStore } from "pinia";
import { ref, computed } from "vue";
import { me } from "@/services/api/services/me/me";
import { destroySession } from "@/services/api/services/sessions/sessions";
import type { CurrentUser } from "@/services/api/models";

export const useCurrentUserStore = defineStore(
  "currentUser",
  () => {
    const user = ref<CurrentUser | undefined>();
    const resolved = ref(false);

    const signedIn = computed(() => user.value !== undefined);

    // Coalesced so concurrent guard runs on the first navigation share one
    // request instead of racing three copies of GET /me.
    let inFlight: Promise<CurrentUser | undefined> | undefined;

    async function load(): Promise<CurrentUser | undefined> {
      if (resolved.value) return user.value;
      if (inFlight) return inFlight;

      inFlight = me()
        .then((current) => {
          user.value = current;
          return current;
        })
        .catch(() => {
          user.value = undefined;
          return undefined;
        })
        .finally(() => {
          resolved.value = true;
          inFlight = undefined;
        });

      return inFlight;
    }

    function set(current: CurrentUser): void {
      user.value = current;
      resolved.value = true;
    }

    // Also used by the 401 interceptor, where the server has already decided
    // the session is gone and there is nothing to sign out of.
    function clear(): void {
      user.value = undefined;
      resolved.value = true;
      inFlight = undefined;
    }

    async function signOut(): Promise<void> {
      try {
        await destroySession();
      } finally {
        clear();
      }
    }

    return { user, resolved, signedIn, load, set, clear, signOut };
  },
  {
    // Only the identity is persisted, so a reload paints the shell before
    // GET /me returns. The cookie remains the only real authority.
    persist: {
      pick: ["user"],
    },
  },
);

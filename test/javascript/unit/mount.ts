import { mount } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { vi } from "vitest";
import Router from "@/frontend/lib/Router";

export default (Component, options = {}) =>
  mount(Component, {
    global: {
      plugins: [
        Router,
        createTestingPinia({
          createSpy: vi.fn,
        }),
      ],
    },
    ...options,
  });

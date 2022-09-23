import { describe, it, expect } from "vitest";

import mountVM from "~/test/javascript/unit/mount";
import MainItems from "../MainItems.vue";
import type { NavigationItem } from "../MainItems.vue";

describe("MainItems", () => {
  it("renders properly", () => {
    const testNavItem: NavigationItem = {
      name: "Test",
      to: { name: "home" },
    };
    const wrapper = mountVM(MainItems, {
      props: {
        items: [testNavItem],
      },
    });

    expect(wrapper.text()).toContain("Test");
  });
});

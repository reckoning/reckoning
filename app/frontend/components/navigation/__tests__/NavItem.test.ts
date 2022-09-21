import { describe, it, expect } from "vitest";

import NavItem from "@/components/navigation/NavItem.vue";
import mountVM from "~/test/javascript/unit/mount";

describe("NavItem", () => {
  it("renders a link", () => {
    const cmp = mountVM(NavItem, {
      title: "Home",
      routeName: "home",
      icon: "fad fa-home",
    });

    expect(cmp.findAll("a")).toHaveLength(1);
  });
});

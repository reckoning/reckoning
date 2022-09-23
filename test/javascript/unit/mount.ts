import { mount } from "@vue/test-utils";
import { createRouter, createWebHistory } from "vue-router";
import { routes } from "@/frontend/routes";
// import type { ComponentOptionsWithObjectProps } from "vue";

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default (Component, propsData = {}) =>
  mount(Component, {
    global: {
      plugins: [router],
    },
    propsData,
  });

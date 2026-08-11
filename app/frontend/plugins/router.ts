import { createRouter, createWebHistory } from "vue-router";
import type { RouteRecordRaw } from "vue-router";
import { useCurrentUserStore } from "@/stores/currentUser";

// Rails mounts the shell under /app (config/routes.rb), so the history base
// has to match or every push would leave the SPA's own mount point.
export const SPA_BASE = "/app";

const routes: RouteRecordRaw[] = [
  {
    path: "/login",
    name: "login",
    component: () => import("@/pages/sessions/LoginPage.vue"),
    meta: { requiresAuth: false },
  },
  {
    path: "/",
    name: "dashboard",
    component: () => import("@/pages/dashboard/DashboardPage.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/customers",
    name: "customers",
    component: () => import("@/pages/customers/CustomersList.vue"),
    meta: { requiresAuth: true },
  },
];

export const router = createRouter({
  history: createWebHistory(SPA_BASE),
  routes,
});

router.beforeEach(async (to) => {
  const currentUser = useCurrentUserStore();

  // The cookie is the authority, so the first navigation of a cold load has to
  // ask the server before it can decide anything.
  await currentUser.load();

  if (to.meta.requiresAuth === true && !currentUser.signedIn) {
    return { name: "login", query: { redirect: to.fullPath } };
  }

  if (to.name === "login" && currentUser.signedIn) {
    return { name: "dashboard" };
  }

  return true;
});

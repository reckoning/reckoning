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
    path: "/password/new",
    name: "password-reset-request",
    component: () => import("@/pages/sessions/PasswordResetRequestPage.vue"),
    meta: { requiresAuth: false },
  },
  {
    // Devise mails a link carrying reset_password_token as a query param.
    path: "/password/edit",
    name: "password-reset",
    component: () => import("@/pages/sessions/PasswordResetPage.vue"),
    meta: { requiresAuth: false },
  },
  {
    path: "/",
    name: "dashboard",
    component: () => import("@/pages/dashboard/DashboardPage.vue"),
    meta: { requiresAuth: true },
  },
  {
    // Devise mails a link carrying confirmation_token as a query param.
    path: "/confirmation",
    name: "confirmation",
    component: () => import("@/pages/sessions/ConfirmationPage.vue"),
    meta: { requiresAuth: false },
  },
  {
    path: "/unlock",
    name: "unlock",
    component: () => import("@/pages/sessions/UnlockPage.vue"),
    meta: { requiresAuth: false },
  },
  {
    path: "/settings/two-factor",
    name: "two-factor",
    component: () => import("@/pages/settings/TwoFactorPage.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/customers",
    name: "customers",
    component: () => import("@/pages/customers/CustomersList.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/customers/:id/edit",
    name: "customer-edit",
    component: () => import("@/pages/customers/CustomerForm.vue"),
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

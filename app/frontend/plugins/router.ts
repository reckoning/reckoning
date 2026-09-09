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
  {
    path: "/projects",
    name: "projects",
    component: () => import("@/pages/projects/ProjectsList.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/projects/new",
    name: "project-new",
    component: () => import("@/pages/projects/ProjectForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/projects/:id/edit",
    name: "project-edit",
    component: () => import("@/pages/projects/ProjectForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/timesheet",
    name: "timesheet",
    component: () => import("@/pages/timesheet/TimesheetPage.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/offers",
    name: "offers",
    component: () => import("@/pages/offers/OffersList.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/offers/new",
    name: "offer-new",
    component: () => import("@/pages/offers/OfferForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/offers/:id",
    name: "offer",
    component: () => import("@/pages/offers/OfferDetail.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/offers/:id/edit",
    name: "offer-edit",
    component: () => import("@/pages/offers/OfferForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/expenses",
    name: "expenses",
    component: () => import("@/pages/expenses/ExpensesList.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/expenses/new",
    name: "expense-new",
    component: () => import("@/pages/expenses/ExpenseForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/expenses/:id/edit",
    name: "expense-edit",
    component: () => import("@/pages/expenses/ExpenseForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/invoices",
    name: "invoices",
    component: () => import("@/pages/invoices/InvoicesList.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/invoices/new",
    name: "invoice-new",
    component: () => import("@/pages/invoices/InvoiceForm.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/invoices/:id",
    name: "invoice",
    component: () => import("@/pages/invoices/InvoiceDetail.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/invoices/:id/edit",
    name: "invoice-edit",
    component: () => import("@/pages/invoices/InvoiceForm.vue"),
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

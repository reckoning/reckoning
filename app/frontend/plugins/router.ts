import { createRouter, createWebHistory } from "vue-router";
import type { RouteRecordRaw } from "vue-router";
import { useCurrentUserStore } from "@/stores/currentUser";

// The SPA is the app: Rails hands it every page load it does not claim for
// the API, an export or the admin (config/routes.rb), so it owns the whole
// path space and needs no prefix of its own.
export const SPA_BASE = "/";

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
    path: "/projects/:id",
    name: "project",
    component: () => import("@/pages/projects/ProjectDetail.vue"),
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
    path: "/settings",
    name: "profile-settings",
    component: () => import("@/pages/settings/ProfileSettings.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/settings/password",
    name: "password-change",
    component: () => import("@/pages/settings/PasswordChange.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/account",
    name: "account-settings",
    component: () => import("@/pages/settings/AccountSettings.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/expenses",
    name: "expenses",
    component: () => import("@/pages/expenses/ExpensesList.vue"),
    meta: { requiresAuth: true },
  },
  {
    path: "/expenses/import",
    name: "expense-import",
    component: () => import("@/pages/expenses/ExpenseImportPage.vue"),
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
  {
    path: "/backend",
    name: "backend",
    component: () => import("@/pages/backend/BackendDashboard.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  {
    path: "/backend/users",
    name: "backend-users",
    component: () => import("@/pages/backend/BackendUsersList.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  {
    path: "/backend/users/new",
    name: "backend-user-new",
    component: () => import("@/pages/backend/BackendUserForm.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  {
    path: "/backend/users/:id/edit",
    name: "backend-user-edit",
    component: () => import("@/pages/backend/BackendUserForm.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  {
    path: "/backend/accounts",
    name: "backend-accounts",
    component: () => import("@/pages/backend/BackendAccountsList.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  {
    path: "/backend/accounts/new",
    name: "backend-account-new",
    component: () => import("@/pages/backend/BackendAccountForm.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  {
    path: "/backend/accounts/:id/edit",
    name: "backend-account-edit",
    component: () => import("@/pages/backend/BackendAccountForm.vue"),
    meta: { requiresAuth: true, requiresAdmin: true },
  },
  // Rails hands every unclaimed page load to the shell, so a typo arrives
  // here rather than at a server-rendered 404.
  {
    path: "/:path(.*)",
    name: "not-found",
    component: () => import("@/pages/NotFoundPage.vue"),
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

  // The backend answers a non-admin with 403, and a screen that renders only
  // errors is worse than not offering it: the dashboard is where they belong.
  //
  // Asked again rather than read off the session: an admin can be demoted —
  // by another admin, or on the very form these screens offer — and the
  // cached answer would keep letting them in until a reload.
  if (to.meta.requiresAdmin === true) {
    const current = await currentUser.refresh();

    if (current?.admin !== true) return { name: "dashboard" };
  }

  return true;
});

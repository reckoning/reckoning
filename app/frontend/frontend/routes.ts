import type { RouteLocation } from "vue-router";
import { format } from "date-fns";
import HomeView from "@/frontend/views/HomeView.vue";
import { v4 as uuidv4 } from "uuid";
import { routes as ProjectsRoutes } from "@/frontend/views/Projects/routes";
import { routes as SettingsRoutes } from "@/frontend/views/Settings/routes";

export const routes = [
  {
    path: "/",
    name: "home",
    component: HomeView,
    meta: {
      title: "home",
    },
  },
  {
    path: "/dashboard/",
    name: "dashboard",
    component: () => import("@/frontend/views/DashboardView.vue"),
    meta: {
      title: "dashboard",
      needsAuthentication: true,
    },
  },
  {
    path: "/invoices/",
    name: "invoices",
    component: () => import("@/frontend/views/InvoicesView.vue"),
    meta: {
      title: "invoices",
      needsAuthentication: true,
    },
  },
  {
    path: "/projects/",
    name: "projects",
    component: () => import("@/frontend/views/ProjectsView.vue"),
    meta: {
      title: "projects",
      needsAuthentication: true,
    },
    redirect: {
      name: "projects-list",
    },
    children: ProjectsRoutes,
  },
  {
    path: "/timers/",
    name: "timers",
    meta: {
      needsAuthentication: true,
    },
    redirect: (_to: RouteLocation) => ({
      name: "timers-year",
      params: {
        year: format(new Date(), "yyyy"),
      },
    }),
  },
  {
    path: "/timers/:year",
    name: "timers-year",
    component: () => import("@/frontend/views/TimersView.vue"),
    meta: {
      title: "timers",
      needsAuthentication: true,
    },
  },
  {
    path: "/expenses/",
    name: "expenses",
    component: () => import("@/frontend/views/ExpensesView.vue"),
    meta: {
      title: "expenses",
      needsAuthentication: true,
    },
  },
  {
    path: "/settings/",
    name: "settings",
    component: () => import("@/frontend/views/SettingsView.vue"),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: "settings-profile",
    },
    children: SettingsRoutes,
  },
  {
    path: "/calculator/",
    name: "calculator",
    redirect: (_to: RouteLocation) => ({
      name: "calculator-item",
      params: {
        id: uuidv4(),
      },
    }),
    meta: {
      needsAuthentication: true,
    },
  },
  {
    path: "/calculator/:id",
    name: "calculator-item",
    component: () => import("@/frontend/views/CalculatorView.vue"),
    meta: {
      title: "calculator",
      needsAuthentication: true,
    },
  },
  // {
  //   path: '/sign-up/',
  //   name: 'signup',
  //   component: () => import('@/frontend/views/SignupView.vue'),
  //   meta: {
  //     title: 'signUp',
  //   },
  // },
  {
    path: "/login/",
    name: "login",
    component: () => import("@/frontend/views/LoginView.vue"),
    meta: {
      title: "login",
    },
  },
  {
    path: "/impressum/",
    name: "impressum",
    component: () => import("@/frontend/views/ImpressumView.vue"),
    meta: {
      title: "impressum",
    },
  },
  {
    path: "/privacy-policy/",
    name: "privacy-policy",
    component: () => import("@/frontend/views/PrivacyPolicyView.vue"),
    meta: {
      title: "privacy-policy",
    },
  },
  // {
  //   path: '/password/request/',
  //   name: 'request-password',
  //   component: () => import('@/frontend/views/RequestPasswordView.vue'),
  //   meta: {
  //     title: 'requestPassword',
  //   },
  // },
  // {
  //   path: '/password/update/:token/',
  //   name: 'change-password',
  //   component: () => import('@/frontend/views/ChangePasswordView.vue'),
  //   meta: {
  //     title: 'changePassword',
  //   },
  // },
  // {
  //   path: '/confirm/:token/',
  //   name: 'confirm',
  //   component: () => import('@/frontend/views/ConfirmView.vue'),
  // },
  {
    path: "/404/",
    name: "404",
    component: () => import("@/frontend/views/NotFoundView.vue"),
    meta: {
      title: "notFound",
    },
  },
  {
    path: "/:catchAll(.*)",
    component: () => import("@/frontend/views/NotFoundView.vue"),
    meta: {
      title: "notFound",
    },
  },
];

export default routes;

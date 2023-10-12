export const routes = [
  {
    path: ".",
    name: "projects-list",
    component: () => import("@/frontend/views/Projects/ListView.vue"),
    meta: {
      title: "projects.index",
      needsAuthentication: true,
    },
  },
  {
    path: ":id",
    name: "project-detail",
    component: () => import("@/frontend/views/Projects/DetailView.vue"),
    meta: {
      title: "projects.detail",
      needsAuthentication: true,
    },
  },
  {
    path: ":id/calculator",
    name: "project-calculator",
    component: () => import("@/frontend/views/Projects/CalculatorView.vue"),
    meta: {
      title: "projects.calculator",
      needsAuthentication: true,
    },
  },
];

export default routes;

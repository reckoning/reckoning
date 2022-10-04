export const routes = [
  {
    path: ".",
    name: "customers-list",
    component: () => import("@/frontend/views/Customers/ListView.vue"),
    meta: {
      title: "customers.index",
      needsAuthentication: true,
    },
  },
  {
    path: ":id",
    name: "customer-detail",
    component: () => import("@/frontend/views/Customers/DetailView.vue"),
    meta: {
      title: "customers.detail",
      needsAuthentication: true,
    },
  },
];

export default routes;

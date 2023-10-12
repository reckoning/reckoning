import { createRouter, createWebHistory } from "vue-router";
import type {
  RouteRecordRaw,
  RouteLocation,
  RouteLocationRaw,
} from "vue-router";
import initialRoutes from "@/frontend/routes";
import useAuthStore from "@/frontend/stores/Auth";
import useAppStore from "@/frontend/stores/App";

const addTrailingSlashToAllRoutes = (
  routes: RouteRecordRaw[]
): RouteRecordRaw[] =>
  routes
    .map((route: RouteRecordRaw): RouteRecordRaw[] => {
      if (["*", "/"].includes(route.path)) {
        return [route];
      }

      const path: string = route.path.replace(/\/$/, "");

      const modifiedRoute: RouteRecordRaw = {
        ...route,
        path: `${path}/`,
      };

      if (route.children && route.children.length > 0) {
        modifiedRoute.children = addTrailingSlashToAllRoutes(route.children);
      }

      return [
        modifiedRoute,
        {
          path,
          redirect: (to: RouteLocation): RouteLocationRaw => ({
            name: route.name,
            params: to.params || null,
            query: to.query || null,
          }),
        },
      ];
    })
    .flat();

const router = createRouter({
  strict: true,
  history: createWebHistory(window.FRONTEND_BASE_URL),
  linkActiveClass: "active",
  linkExactActiveClass: "active-exact",
  routes: addTrailingSlashToAllRoutes(initialRoutes),
  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
      setTimeout(() => {
        if (to.hash) {
          resolve(false);
        } else if (savedPosition) {
          resolve(savedPosition);
        } else {
          resolve({ left: 0, top: 0 });
        }
      }, 200);
    }),
});

router.afterEach(() => {
  const appStore = useAppStore();

  if (appStore.navigationOpen) {
    appStore.closeNavigation();
  }
});

router.beforeEach((to) => {
  const authStore = useAuthStore();

  if (to.meta.needsAuthentication && !authStore.authenticated) {
    return {
      name: "login",
    };
  }

  return true;
});

export default router;

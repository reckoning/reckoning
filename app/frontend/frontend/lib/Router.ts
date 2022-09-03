import { createRouter, createWebHistory } from 'vue-router'
import initialRoutes from '@/frontend/routes'
import useAuthStore from '@/frontend/stores/Auth'

const addTrailingSlashToAllRoutes = (routes) =>
  [].concat(
    ...routes.map((route) => {
      if (['*', '/'].includes(route.path)) {
        return [route]
      }

      const { pathToRegexpOptions = {} } = route

      const path = route.path.replace(/\/$/, '')

      const modifiedRoute = {
        ...route,
        pathToRegexpOptions: {
          ...pathToRegexpOptions,
          strict: true,
        },
        path: `${path}/`,
      }

      if (route.children && route.children.length > 0) {
        modifiedRoute.children = addTrailingSlashToAllRoutes(route.children)
      }

      return [
        modifiedRoute,
        {
          path,
          redirect: (to) => ({
            name: route.name,
            params: to.params || null,
            query: to.query || null,
          }),
        },
      ]
    })
  )

const router = createRouter({
  strict: true,
  history: createWebHistory(),
  linkActiveClass: 'active',
  linkExactActiveClass: 'active-exact',
  routes: addTrailingSlashToAllRoutes(initialRoutes),
  scrollBehavior: (to, _from, savedPosition) =>
    new Promise((resolve) => {
      setTimeout(() => {
        if (to.hash) {
          resolve(false)
        } else if (savedPosition) {
          resolve(savedPosition)
        } else {
          resolve({ left: 0, top: 0 })
        }
      }, 200)
    }),
})

router.beforeEach((to, _from) => {
  const authStore = useAuthStore()

  if (to.meta.needsAuthentication && !authStore.authenticated) {
    return {
      name: 'login',
    }
  }

  return true
})

export default router

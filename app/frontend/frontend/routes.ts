import { routes as SettingsRoutes } from '@/frontend/pages/Settings/routes'

export const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/frontend/pages/HomePage.vue'),
    meta: {
      title: 'home',
    },
  },
  {
    path: '/dashboard/',
    name: 'dashboard',
    component: () => import('@/frontend/pages/DashboardPage.vue'),
    meta: {
      title: 'dashboard',
      needsAuthentication: true,
    },
  },
  {
    path: '/invoices/',
    name: 'invoices',
    component: () => import('@/frontend/pages/InvoicesPage.vue'),
    meta: {
      title: 'invoices',
      needsAuthentication: true,
    },
  },
  {
    path: '/projects/',
    name: 'projects',
    component: () => import('@/frontend/pages/ProjectsPage.vue'),
    meta: {
      title: 'projects',
      needsAuthentication: true,
    },
  },
  {
    path: '/timers/',
    name: 'timers',
    component: () => import('@/frontend/pages/TimersPage.vue'),
    meta: {
      title: 'timers',
      needsAuthentication: true,
    },
  },
  {
    path: '/expenses/',
    name: 'expenses',
    component: () => import('@/frontend/pages/ExpensesPage.vue'),
    meta: {
      title: 'expenses',
      needsAuthentication: true,
    },
  },
  {
    path: '/settings/',
    name: 'settings',
    component: () => import('@/frontend/pages/SettingsPage.vue'),
    meta: {
      needsAuthentication: true,
    },
    redirect: {
      name: 'settings-profile',
    },
    children: SettingsRoutes,
  },
  // {
  //   path: '/sign-up/',
  //   name: 'signup',
  //   component: () => import('@/frontend/pages/SignupPage.vue'),
  //   meta: {
  //     title: 'signUp',
  //   },
  // },
  {
    path: '/login/',
    name: 'login',
    component: () => import('@/frontend/pages/LoginPage.vue'),
    meta: {
      title: 'login',
    },
  },
  {
    path: '/impressum/',
    name: 'impressum',
    component: () => import('@/frontend/pages/ImpressumPage.vue'),
    meta: {
      title: 'impressum',
    },
  },
  {
    path: '/privacy-policy/',
    name: 'privacy-policy',
    component: () => import('@/frontend/pages/PrivacyPolicyPage.vue'),
    meta: {
      title: 'privacy-policy',
    },
  },
  // {
  //   path: '/password/request/',
  //   name: 'request-password',
  //   component: () => import('@/frontend/pages/RequestPasswordPage.vue'),
  //   meta: {
  //     title: 'requestPassword',
  //   },
  // },
  // {
  //   path: '/password/update/:token/',
  //   name: 'change-password',
  //   component: () => import('@/frontend/pages/ChangePasswordPage.vue'),
  //   meta: {
  //     title: 'changePassword',
  //   },
  // },
  // {
  //   path: '/confirm/:token/',
  //   name: 'confirm',
  //   component: () => import('@/frontend/pages/ConfirmPage.vue'),
  // },
  {
    path: '/404/',
    name: '404',
    component: () => import('@/frontend/pages/NotFoundPage.vue'),
    meta: {
      title: 'notFound',
    },
  },
  {
    path: '/:catchAll(.*)',
    component: () => import('@/frontend/pages/NotFoundPage.vue'),
    meta: {
      title: 'notFound',
    },
  },
]

export default routes

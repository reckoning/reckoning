// import SecurityRoutes from './Security/routes'

export const routes = [
  {
    path: 'profile/',
    name: 'settings-profile',
    component: () => import('@/frontend/pages/Settings/ProfilePage.vue'),
    meta: {
      title: 'settings.index',
      needsAuthentication: true,
    },
  },
  // {
  //   path: 'account/',
  //   name: 'settings-account',
  //   component: () => import('@/frontend/pages/Settings/AccountPage.vue'),
  //   meta: {
  //     title: 'settings.account',
  //     needsAuthentication: true,
  //   },
  // },
  // {
  //   path: 'notifications/',
  //   name: 'settings-notifications',
  //   component: () =>
  //     import('@/frontend/pages/Settings/Notifications/index.vue'),
  //   meta: {
  //     title: 'settings.notifications',
  //     needsAuthentication: true,
  //   },
  // },
  // {
  //   path: 'security/',
  //   name: 'settings-security',
  //   component: () => import('@/frontend/pages/Settings/Security/index.vue'),
  //   meta: {
  //     needsAuthentication: true,
  //   },
  //   redirect: {
  //     name: 'settings-security-status',
  //   },
  //   children: SecurityRoutes,
  // },
]

export default routes

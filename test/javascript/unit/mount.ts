import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import { routes } from '@/frontend/routes'

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default (Component: any, propsData = {}) =>
  mount(Component, {
    global: {
      plugins: [router],
    },
    propsData,
  })

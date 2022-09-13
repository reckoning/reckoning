<template>
  <div class="relative overflow-hidden bg-gray-800 min-h-screen">
    <div class="hidden sm:absolute sm:inset-0 sm:block" aria-hidden="true">
      <svg
        class="absolute bottom-0 right-0 mb-48 translate-x-1/2 transform text-gray-700 lg:top-0 lg:mt-28 lg:mb-0 xl:translate-x-0 xl:transform-none"
        width="364"
        height="384"
        viewBox="0 0 364 384"
        fill="none"
      >
        <defs>
          <pattern
            id="eab71dd9-9d7a-47bd-8044-256344ee00d0"
            x="0"
            y="0"
            width="20"
            height="20"
            patternUnits="userSpaceOnUse"
          >
            <rect x="0" y="0" width="4" height="4" fill="currentColor" />
          </pattern>
        </defs>
        <rect
          width="364"
          height="384"
          fill="url(#eab71dd9-9d7a-47bd-8044-256344ee00d0)"
        />
      </svg>
    </div>
    <div class="relative pt-6 pb-16 sm:pb-24">
      <div>
        <nav
          class="relative mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6"
          aria-label="Global"
        >
          <div class="flex flex-1 items-center">
            <div class="flex w-full items-center justify-between md:w-auto">
              <router-link
                :to="{ name: 'home' }"
                class="brand text-2xl font-medium text-white hover:text-gray-300"
              >
                Reckoning
              </router-link>
              <div class="-mr-2 flex items-center md:hidden">
                <button
                  type="button"
                  class="focus-ring-inset inline-flex items-center justify-center rounded-md bg-gray-800 p-2 text-gray-400 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-white"
                  aria-expanded="false"
                >
                  <span class="sr-only">Open main menu</span>
                  <!-- Heroicon name: outline/bars-3 -->
                  <svg
                    class="h-6 w-6"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                    />
                  </svg>
                </button>
              </div>
            </div>
          </div>
          <div class="hidden md:flex">
            <router-link
              :to="{
                name: 'login',
              }"
              class="inline-flex items-center rounded-md border border-transparent bg-gray-600 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700"
            >
              Log in
            </router-link>
          </div>
        </nav>
      </div>

      <main class="mt-16 sm:mt-24">
        <div class="mx-auto max-w-7xl">
          <div class="lg:grid lg:grid-cols-12 lg:gap-8">
            <div
              class="px-4 sm:px-6 sm:text-center md:mx-auto md:max-w-2xl lg:col-span-6 lg:flex lg:items-center lg:text-left"
            >
              <div>
                <h1
                  class="mt-4 text-4xl tracking-tight text-white sm:text-5xl md:text-6xl"
                >
                  Create Invoices with ease
                </h1>
                <p
                  class="mt-3 text-base text-gray-300 sm:mt-5 sm:text-xl lg:text-lg xl:text-xl"
                >
                  Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure
                  qui lorem cupidatat commodo. Elit sunt amet fugiat veniam
                  occaecat fugiat aliqua ad ad non deserunt sunt.
                </p>
              </div>
            </div>
            <div class="mt-16 sm:mt-24 lg:col-span-6 lg:mt-0">
              <div
                class="bg-white sm:mx-auto sm:w-full sm:max-w-md sm:overflow-hidden sm:rounded-lg"
              >
                <div class="px-4 py-8 sm:px-10">
                  <div>
                    <p class="text-sm font-medium text-gray-700">
                      Sign in with
                    </p>

                    <div class="mt-1 grid grid-cols-4 gap-3">
                      <div>
                        <router-link
                          :to="{
                            name: 'login',
                          }"
                          class="inline-flex h-10 items-center w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 font-medium text-gray-500 shadow-sm hover:bg-gray-50"
                        >
                          <span class="sr-only">Sign in with your Email</span>
                          <i class="fad fa-envelope"></i>
                        </router-link>
                      </div>

                      <div>
                        <a
                          href="#"
                          class="inline-flex h-10 items-center w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 font-medium text-gray-500 shadow-sm hover:bg-gray-50"
                        >
                          <span class="sr-only">Sign in with Google</span>
                          <i class="fa fa-google"></i>
                        </a>
                      </div>

                      <div>
                        <a
                          href="#"
                          class="inline-flex h-10 items-center w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 font-medium text-gray-500 shadow-sm hover:bg-gray-50"
                        >
                          <span class="sr-only">Sign in with Dropbox</span>
                          <i class="fa fa-dropbox"></i>
                        </a>
                      </div>

                      <div>
                        <a
                          href="#"
                          class="inline-flex h-10 items-center w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 font-medium text-gray-500 shadow-sm hover:bg-gray-50"
                        >
                          <span class="sr-only">Sign in with GitHub</span>
                          <i class="fa fa-github"></i>
                        </a>
                      </div>
                    </div>
                  </div>

                  <div class="relative mt-6">
                    <div
                      class="absolute inset-0 flex items-center"
                      aria-hidden="true"
                    >
                      <div class="w-full border-t border-gray-300"></div>
                    </div>
                    <div class="relative flex justify-center text-sm">
                      <span class="bg-white px-2 text-gray-500">Or</span>
                    </div>
                  </div>

                  <div class="mt-6">
                    <form action="#" method="POST" class="space-y-6">
                      <div>
                        <label for="name" class="sr-only">Full name</label>
                        <input
                          id="name"
                          type="text"
                          name="name"
                          autocomplete="name"
                          placeholder="Full name"
                          required
                          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        />
                      </div>

                      <div>
                        <label for="mobile-or-email" class="sr-only"
                          >Mobile number or email</label
                        >
                        <input
                          id="mobile-or-email"
                          type="text"
                          name="mobile-or-email"
                          autocomplete="email"
                          placeholder="Mobile number or email"
                          required
                          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        />
                      </div>

                      <div>
                        <label for="password" class="sr-only">Password</label>
                        <input
                          id="password"
                          name="password"
                          type="password"
                          placeholder="Password"
                          autocomplete="current-password"
                          required
                          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                        />
                      </div>

                      <div>
                        <button
                          type="submit"
                          class="flex w-full justify-center rounded-md border border-transparent bg-brand-primary py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                        >
                          Create your account
                        </button>
                      </div>
                    </form>
                  </div>
                </div>
                <div
                  class="border-t-2 border-gray-200 bg-gray-50 px-4 py-6 sm:px-10"
                >
                  <p class="text-xs leading-5 text-gray-500">
                    By signing up, you agree to our
                    <a
                      href="#"
                      class="font-medium text-gray-900 hover:underline"
                      >Terms</a
                    >
                    and
                    <router-link
                      :to="{ name: 'privacy-policy' }"
                      class="font-medium text-gray-900 hover:underline"
                    >
                      Privacy Policy </router-link
                    >.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { onBeforeMount } from 'vue'
import { useRouter } from 'vue-router'
import useAuthStore from '@/frontend/stores/Auth'

const authStore = useAuthStore()
const router = useRouter()

onBeforeMount(() => {
  if (authStore.authenticated) {
    router.push({ name: 'dashboard' })
  }
})
</script>

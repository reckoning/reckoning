<template>
  <!--
  This example requires Tailwind CSS v2.0+

  This example requires some changes to your config:

  ```
  // tailwind.config.js
  module.exports = {
    // ...
    plugins: [
      // ...
      require('@tailwindcss/forms'),
    ],
  }
  ```
-->
  <!--
  This example requires updating your template:

  ```
  <html class="h-full bg-gray-50">
  <body class="h-full">
  ```
-->
  <div class="flex min-h-full flex-col justify-center py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <h1 class="mt-6 text-center text-3xl tracking-tight text-gray-900">
        <router-link :to="{ name: 'home' }">Reckoning</router-link>
      </h1>
      <h2 class="mt-6 text-center text-2xl tracking-tight text-gray-900">
        Sign in to your account
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        Or
        <a href="#" class="font-medium text-brand-primary hover:text-indigo-500"
          >start your 14-day free trial</a
        >
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <Form
          v-slot="{ isSubmitting }"
          :validation-schema="loginSchema"
          :initial-values="formValues"
          class="space-y-6"
          @submit="onSubmit"
        >
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700"
              >Email address</label
            >
            <div class="mt-1">
              <Field
                id="email"
                name="email"
                type="email"
                autocomplete="email"
                required
                class="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />

              <ErrorMessage name="email" class="text-red-700 font-light" />
            </div>
          </div>

          <div>
            <label
              for="password"
              class="block text-sm font-medium text-gray-700"
              >Password</label
            >
            <div class="mt-1">
              <Field
                id="password"
                name="password"
                type="password"
                required
                class="block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />
              <ErrorMessage name="password" class="text-red-700 font-light" />
            </div>
          </div>

          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <Field
                id="remember-me"
                name="rememberMe"
                type="checkbox"
                :value="true"
                class="h-4 w-4 rounded border-gray-300 text-brand-primary focus:ring-brand-primary"
              />
              <label for="remember-me" class="ml-2 block text-sm text-gray-900"
                >Remember me</label
              >
            </div>

            <div class="text-sm">
              <a
                href="#"
                class="font-medium text-brand-primary hover:text-indigo-500"
                >Forgot your password?</a
              >
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="flex w-full justify-center rounded-md border border-transparent bg-brand-primary py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              :disabled="isSubmitting"
            >
              Sign in
            </button>
          </div>
        </Form>

        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="bg-white px-2 text-gray-500">Or continue with</span>
            </div>
          </div>

          <div class="mt-6 grid grid-cols-3 gap-3">
            <div>
              <a
                href="#"
                class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-500 shadow-sm hover:bg-gray-50"
              >
                <span class="sr-only">Sign in with Google</span>
                <i class="fa fa-google"></i>
              </a>
            </div>

            <div>
              <a
                href="#"
                class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-500 shadow-sm hover:bg-gray-50"
              >
                <span class="sr-only">Sign in with Dropbox</span>
                <i class="fa fa-dropbox"></i>
              </a>
            </div>

            <div>
              <a
                href="#"
                class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-500 shadow-sm hover:bg-gray-50"
              >
                <span class="sr-only">Sign in with GitHub</span>
                <i class="fa fa-github"></i>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { Form, Field, ErrorMessage } from 'vee-validate'
import * as yup from 'yup'
import { useRouter, useRoute, RouteRecordName } from 'vue-router'
import useAuthStore from '@/frontend/stores/Auth'
import { sessions } from '@/frontend/api'
import { ApiError } from '@/frontend/api/client/core/ApiError'

const router = useRouter()
const route = useRoute()

const loginSchema = yup.object({
  email: yup.string().required().email(),
  password: yup.string().required().min(8),
  rememberMe: yup.boolean(),
})

const formValues = {
  rememberMe: false,
}

const authStore = useAuthStore()

const onSubmit = async (values, { resetForm, setFieldError }) => {
  try {
    await sessions.createSession(values)

    resetForm()

    authStore.login()

    if (route.redirectedFrom) {
      router.push({ name: route.redirectedFrom.name as RouteRecordName })
    } else {
      router.push({ name: 'home' })
    }
  } catch (error) {
    setFieldError('email', (error as ApiError).body.message)
  }
}
</script>

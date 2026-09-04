<script setup lang="ts">
import { ref, computed } from "vue"
import { useRouter, useRoute, RouterLink } from "vue-router"
import { safeReturnPath } from "@/lib/return-path"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import { createSession } from "@/services/api/services/sessions/sessions"
import { useAppConfig } from "@/composables/useAppConfig"
import { useCurrentUserStore } from "@/stores/currentUser"

const { t } = useI18n()
const router = useRouter()
const route = useRoute()
const currentUser = useCurrentUserStore()
const { config } = useAppConfig()

const failed = ref(false)

const registrationEnabled = computed(() => config.value?.registrationEnabled === true)
const accountName = computed(() => config.value?.accountName ?? null)

const schema = toTypedSchema(
  z.object({
    email: z
      .string({ message: t("validation.emailRequired") })
      .min(1, t("validation.emailRequired"))
      .email(t("validation.emailInvalid")),
    password: z
      .string({ message: t("validation.passwordRequired") })
      .min(1, t("validation.passwordRequired")),
    otpToken: z.string().optional(),
    rememberMe: z.boolean().optional(),
  }),
)

const { handleSubmit, errors, defineField, isSubmitting } = useForm({
  validationSchema: schema,
  initialValues: { rememberMe: false },
})

const [email, emailAttrs] = defineField("email")
const [password, passwordAttrs] = defineField("password")
const [otpToken, otpTokenAttrs] = defineField("otpToken")
const [rememberMe] = defineField("rememberMe")

const onSubmit = handleSubmit(async (values) => {
  failed.value = false

  try {
    // POST /sessions sets the session cookie as well as returning a token, so
    // the SPA ignores the token and reloads identity from /me.
    await createSession({
      email: values.email,
      password: values.password,
      ...(values.otpToken ? { otp_token: values.otpToken } : {}),
      ...(values.rememberMe ? { remember_me: true } : {}),
    })

    const user = await currentUser.refresh()

    if (!user) {
      failed.value = true
      return
    }

    // A server-rendered screen sent us here. It lives outside the SPA, so
    // going back to it is a page load, not a route change.
    const returnTo = safeReturnPath(route.query.return)
    if (returnTo) {
      window.location.assign(returnTo)
      return
    }

    const redirect = route.query.redirect
    await router.replace(typeof redirect === "string" ? redirect : { name: "dashboard" })
  } catch {
    failed.value = true
  }
})
</script>

<template>
  <div class="mx-auto mt-[12%] w-full max-w-[300px] px-3 md:px-0">
    <h1 class="mb-5 text-center font-brand text-[30px] font-medium leading-tight">
      <a href="/" class="text-brand no-underline hover:no-underline">{{ t("brand") }}</a>
      <small v-if="accountName" class="block text-[65%] text-muted" data-test="account-name">
        {{ accountName }}
      </small>
    </h1>

    <form novalidate @submit="onSubmit">
      <div class="mb-[15px]">
        <input
          v-model="email"
          v-bind="emailAttrs"
          type="email"
          autocomplete="username"
          autofocus
          :placeholder="t('login.email')"
          data-test="email"
          class="block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
        <p v-if="errors.email" data-test="email-error" class="mt-1 text-[13px] text-[#a94442]">
          {{ errors.email }}
        </p>
      </div>

      <div class="mb-[15px]">
        <input
          v-model="password"
          v-bind="passwordAttrs"
          type="password"
          autocomplete="current-password"
          :placeholder="t('login.password')"
          data-test="password"
          class="block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
        <p v-if="errors.password" data-test="password-error" class="mt-1 text-[13px] text-[#a94442]">
          {{ errors.password }}
        </p>
      </div>

      <div class="mb-[15px]">
        <input
          v-model="otpToken"
          v-bind="otpTokenAttrs"
          type="text"
          inputmode="numeric"
          autocomplete="one-time-code"
          :placeholder="t('login.otpToken')"
          data-test="otp-token"
          class="block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
      </div>

      <div class="mb-[10px] flex items-center gap-2">
        <input
          id="remember-me"
          v-model="rememberMe"
          type="checkbox"
          data-test="remember-me"
          class="h-[18px] w-[18px] rounded-[4px] border border-[#b9c2cc] accent-brand"
        />
        <label for="remember-me" class="text-[14px] font-normal text-muted">
          {{ t("login.rememberMe") }}
        </label>
      </div>

      <p v-if="failed" data-test="login-failed" class="mb-[10px] text-[14px] text-[#a94442]">
        {{ t("login.failed") }}
      </p>

      <button
        type="submit"
        data-test="submit"
        :disabled="isSubmitting"
        class="block w-full rounded-md border border-brand-border bg-brand px-4 py-[10px] text-[18px] font-normal text-white hover:bg-[#3276b1] disabled:opacity-65"
      >
        {{ isSubmitting ? t("login.submitting") : t("login.submit") }}
      </button>

      <div class="text-center">
        <RouterLink
          :to="{ name: 'password-reset-request' }"
          data-test="reset-password"
          class="inline-block px-3 py-[6px] text-[14px] text-brand hover:underline"
        >
          {{ t("login.resetPassword") }}
        </RouterLink>
      </div>

      <template v-if="registrationEnabled">
        <hr class="my-5 border-t border-rule" />
        <p class="mb-[10px] text-center text-[14px]">{{ t("login.signUpPrompt") }}</p>
        <!-- Still the server-rendered screen: signup picks a plan, and no
             endpoint lists them yet. A full page load between old and new is
             expected during the migration. -->
        <a
          href="/signup"
          data-test="sign-up"
          class="block w-full rounded border border-field-border bg-white px-3 py-[6px] text-center text-[14px] text-ink hover:bg-[#e6e6e6]"
        >
          {{ t("login.signUp") }}
        </a>
      </template>
    </form>
  </div>
</template>

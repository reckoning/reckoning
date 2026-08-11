<script setup lang="ts">
import { ref } from "vue"
import { useRouter, useRoute } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import { createSession } from "@/services/api/services/sessions/sessions"
import { useCurrentUserStore } from "@/stores/currentUser"

const { t } = useI18n()
const router = useRouter()
const route = useRoute()
const currentUser = useCurrentUserStore()

const failed = ref(false)

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
  }),
)

const { handleSubmit, errors, defineField, isSubmitting } = useForm({
  validationSchema: schema,
})

const [email, emailAttrs] = defineField("email")
const [password, passwordAttrs] = defineField("password")
const [otpToken, otpTokenAttrs] = defineField("otpToken")

const onSubmit = handleSubmit(async (values) => {
  failed.value = false

  try {
    // POST /sessions sets the session cookie as well as returning a token, so
    // the SPA ignores the token and reloads identity from /me.
    await createSession({
      email: values.email,
      password: values.password,
      ...(values.otpToken ? { otp_token: values.otpToken } : {}),
    })

    currentUser.clear()
    const user = await currentUser.load()

    if (!user) {
      failed.value = true
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
  <div class="mx-auto mt-16 w-full max-w-sm">
    <h1 class="mb-6 text-2xl font-semibold">{{ t("login.title") }}</h1>

    <form class="space-y-4" novalidate @submit="onSubmit">
      <div>
        <label class="mb-1 block text-sm font-medium" for="email">
          {{ t("login.email") }}
        </label>
        <input
          id="email"
          v-model="email"
          v-bind="emailAttrs"
          type="email"
          autocomplete="username"
          data-testid="email"
          class="w-full rounded border border-gray-300 px-3 py-2"
        />
        <p v-if="errors.email" data-testid="email-error" class="mt-1 text-sm text-red-600">
          {{ errors.email }}
        </p>
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium" for="password">
          {{ t("login.password") }}
        </label>
        <input
          id="password"
          v-model="password"
          v-bind="passwordAttrs"
          type="password"
          autocomplete="current-password"
          data-testid="password"
          class="w-full rounded border border-gray-300 px-3 py-2"
        />
        <p v-if="errors.password" data-testid="password-error" class="mt-1 text-sm text-red-600">
          {{ errors.password }}
        </p>
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium" for="otp-token">
          {{ t("login.otpToken") }}
        </label>
        <input
          id="otp-token"
          v-model="otpToken"
          v-bind="otpTokenAttrs"
          type="text"
          inputmode="numeric"
          autocomplete="one-time-code"
          data-testid="otp-token"
          class="w-full rounded border border-gray-300 px-3 py-2"
        />
      </div>

      <p v-if="failed" data-testid="login-failed" class="text-sm text-red-600">
        {{ t("login.failed") }}
      </p>

      <button
        type="submit"
        data-testid="submit"
        :disabled="isSubmitting"
        class="w-full rounded bg-blue-600 px-4 py-2 font-medium text-white disabled:opacity-50"
      >
        {{ isSubmitting ? t("login.submitting") : t("login.submit") }}
      </button>
    </form>
  </div>
</template>

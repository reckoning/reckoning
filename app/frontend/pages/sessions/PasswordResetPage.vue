<script setup lang="ts">
import { ref } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import { resetPassword } from "@/services/api/services/passwords/passwords"

const { t } = useI18n()
const route = useRoute()
const router = useRouter()

const failed = ref(false)

// Devise puts the token in the link it mails out.
const token = String(route.query.reset_password_token ?? "")

const schema = toTypedSchema(
  z.object({
    password: z
      .string({ message: t("validation.passwordRequired") })
      .min(8, t("validation.passwordRequired")),
    passwordConfirmation: z.string().optional(),
  }),
)

const { handleSubmit, errors, defineField, isSubmitting } = useForm({ validationSchema: schema })
const [password, passwordAttrs] = defineField("password")
const [passwordConfirmation, passwordConfirmationAttrs] = defineField("passwordConfirmation")

const onSubmit = handleSubmit(async (values) => {
  failed.value = false

  try {
    await resetPassword({
      reset_password_token: token,
      password: values.password,
      ...(values.passwordConfirmation
        ? { password_confirmation: values.passwordConfirmation }
        : {}),
    })

    await router.replace({ name: "login" })
  } catch {
    failed.value = true
  }
})
</script>

<template>
  <div class="mx-auto mt-[12%] w-full max-w-[300px] px-3 md:px-0">
    <h1 class="mb-5 text-center font-brand text-[30px] font-medium leading-tight">
      <a href="/" class="text-brand no-underline hover:no-underline">{{ t("brand") }}</a>
    </h1>

    <form novalidate @submit="onSubmit">
      <p class="mb-[15px] text-center text-[14px]">{{ t("passwordReset.resetTitle") }}</p>

      <div class="mb-[15px]">
        <input
          v-model="password"
          v-bind="passwordAttrs"
          type="password"
          autocomplete="new-password"
          autofocus
          :placeholder="t('passwordReset.password')"
          data-test="password"
          class="block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
        <p v-if="errors.password" data-test="password-error" class="mt-1 text-[13px] text-[#a94442]">
          {{ errors.password }}
        </p>
      </div>

      <div class="mb-[15px]">
        <input
          v-model="passwordConfirmation"
          v-bind="passwordConfirmationAttrs"
          type="password"
          autocomplete="new-password"
          :placeholder="t('passwordReset.passwordConfirmation')"
          data-test="password-confirmation"
          class="block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
      </div>

      <p v-if="failed" data-test="reset-failed" class="mb-[10px] text-[14px] text-[#a94442]">
        {{ t("passwordReset.failed") }}
      </p>

      <button
        type="submit"
        data-test="submit"
        :disabled="isSubmitting"
        class="block w-full rounded-md border border-brand-border bg-brand px-4 py-[10px] text-[18px] font-normal text-white hover:bg-[#3276b1] disabled:opacity-65"
      >
        {{ isSubmitting ? t("login.submitting") : t("passwordReset.resetSubmit") }}
      </button>
    </form>

    <div class="text-center">
      <RouterLink
        :to="{ name: 'login' }"
        data-test="back-to-login"
        class="inline-block px-3 py-[6px] text-[14px] text-brand hover:underline"
      >
        {{ t("passwordReset.backToLogin") }}
      </RouterLink>
    </div>
  </div>
</template>

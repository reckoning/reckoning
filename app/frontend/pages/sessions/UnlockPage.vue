<script setup lang="ts">
import { ref, onMounted } from "vue"
import { useRoute, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import { unlockAccount, requestUnlock } from "@/services/api/services/unlocks/unlocks"

const { t } = useI18n()
const route = useRoute()

const message = ref<string | undefined>()
const failed = ref(false)
const redeeming = ref(false)

// Locking is by failed attempts and unlocking is by email, so this link is the
// only way back into a locked account.
const token = String(route.query.unlock_token ?? "")

onMounted(async () => {
  if (!token) return

  redeeming.value = true

  try {
    const result = await unlockAccount({ unlock_token: token })
    message.value = result.message
  } catch {
    failed.value = true
  } finally {
    redeeming.value = false
  }
})

const schema = toTypedSchema(
  z.object({
    email: z
      .string({ message: t("validation.emailRequired") })
      .min(1, t("validation.emailRequired"))
      .email(t("validation.emailInvalid")),
  }),
)

const { handleSubmit, errors, defineField, isSubmitting } = useForm({ validationSchema: schema })
const [email, emailAttrs] = defineField("email")

const onSubmit = handleSubmit(async (values) => {
  failed.value = false

  try {
    const result = await requestUnlock({ email: values.email })
    message.value = result.message
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

    <p v-if="redeeming" data-test="unlocking" class="mb-[15px] text-center text-[14px]">
      {{ t("unlock.unlocking") }}
    </p>

    <p v-else-if="message" data-test="unlock-message" class="mb-[15px] text-[14px]">
      {{ message }}
    </p>

    <template v-else>
      <p v-if="failed" data-test="unlock-failed" class="mb-[10px] text-[14px] text-danger">
        {{ t("unlock.failed") }}
      </p>

      <form novalidate @submit="onSubmit">
        <p class="mb-[15px] text-center text-[14px]">{{ t("unlock.resendPrompt") }}</p>

        <div class="mb-[15px]">
          <input
            v-model="email"
            v-bind="emailAttrs"
            type="email"
            autocomplete="username"
            autofocus
            :placeholder="t('login.email')"
            data-test="email"
            class="block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-placeholder focus:border-field-focus focus:outline-none"
          />
          <p v-if="errors.email" data-test="email-error" class="mt-1 text-[13px] text-danger">
            {{ errors.email }}
          </p>
        </div>

        <button
          type="submit"
          data-test="submit"
          :disabled="isSubmitting"
          class="block w-full rounded-md border border-brand-border bg-brand px-4 py-[10px] text-[18px] font-normal text-white hover:bg-brand-hover disabled:opacity-65"
        >
          {{ isSubmitting ? t("login.submitting") : t("unlock.resend") }}
        </button>
      </form>
    </template>

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

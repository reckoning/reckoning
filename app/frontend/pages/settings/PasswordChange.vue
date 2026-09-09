<script setup lang="ts">
import { ref } from "vue"
import { useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import type { AxiosError } from "axios"
import { useUpdateMyPassword } from "@/services/api/services/me/me"
import { useToastsStore } from "@/stores/toasts"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiFormGroup from "@/components/ui/UiFormGroup.vue"

const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const { mutateAsync: change } = useUpdateMyPassword()

// Devise's own rules, said here rather than after a round trip: the current
// password proves it is you, and the new one is at least eight characters
// and typed twice.
const schema = toTypedSchema(
  z
    .object({
      current_password: z.string().min(1),
      password: z.string().min(8),
      password_confirmation: z.string().min(1),
    })
    .refine((values) => values.password === values.password_confirmation, {
      path: ["password_confirmation"],
      message: "mismatch",
    }),
)

const { defineField, handleSubmit, errors } = useForm({ validationSchema: schema })

const [currentPassword, currentPasswordAttrs] = defineField("current_password")
const [password, passwordAttrs] = defineField("password")
const [passwordConfirmation, passwordConfirmationAttrs] = defineField("password_confirmation")

const busy = ref(false)
// The endpoint refuses a wrong current password, which is the one thing this
// form cannot know in advance. Anything else that goes wrong — a session
// that ran out, no network — is not that, and saying so would send someone
// after a fix that cannot work.
const refused = ref(false)
const failed = ref(false)

const save = handleSubmit(async (values) => {
  busy.value = true
  refused.value = false
  failed.value = false

  try {
    await change({ data: values })
    toasts.push("success", t("passwordChange.saved"))
    await router.push({ name: "profile-settings", hash: "#security" })
  } catch (error) {
    const answered = (error as AxiosError<{errors?: Record<string, unknown>}>).response?.data

    if (answered?.errors && "current_password" in answered.errors) {
      refused.value = true
    } else {
      failed.value = true
    }
  } finally {
    busy.value = false
  }
})

const FIELD = "bs-input"
</script>

<template>
  <div id="password-change">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow">{{ t("passwordChange.title") }}</h1>

      <RouterLink :to="{ name: 'profile-settings', hash: '#security' }" data-test="back">
        <UiButton as="span">{{ t("passwordChange.back") }}</UiButton>
      </RouterLink>
    </div>

    <form class="mt-4 max-w-lg" @submit="save">
      <p v-if="refused" class="mb-4 text-danger-text" data-test="refused">
        {{ t("passwordChange.refused") }}
      </p>
      <p v-else-if="failed" class="mb-4 text-danger-text" data-test="failed">
        {{ t("passwordChange.failed") }}
      </p>

      <UiFormGroup :label="t('passwordChange.fields.currentPassword')">
        <input
          v-model="currentPassword"
          v-bind="currentPasswordAttrs"
          type="password"
          autocomplete="current-password"
          :class="FIELD"
          data-test="current-password"
        />
        <template #error>
          <span v-if="errors.current_password" class="mt-1 block text-danger-text" data-test="current-password-error">
            {{ t("passwordChange.required") }}
          </span>
        </template>
      </UiFormGroup>

      <UiFormGroup :label="t('passwordChange.fields.password')">
        <input
          v-model="password"
          v-bind="passwordAttrs"
          type="password"
          autocomplete="new-password"
          :class="FIELD"
          data-test="password"
        />
        <template #error>
          <span v-if="errors.password" class="mt-1 block text-danger-text" data-test="password-error">
            {{ t("passwordChange.tooShort") }}
          </span>
        </template>
      </UiFormGroup>

      <UiFormGroup :label="t('passwordChange.fields.passwordConfirmation')">
        <input
          v-model="passwordConfirmation"
          v-bind="passwordConfirmationAttrs"
          type="password"
          autocomplete="new-password"
          :class="FIELD"
          data-test="password-confirmation"
        />
        <template #error>
          <span v-if="errors.password_confirmation" class="mt-1 block text-danger-text" data-test="password-confirmation-error">
            {{ t("passwordChange.mismatch") }}
          </span>
        </template>
      </UiFormGroup>

      <UiFormActions
        :save-label="t('passwordChange.save')"
        :cancel-label="t('passwordChange.cancel')"
        :busy="busy"
        @cancel="router.push({ name: 'profile-settings', hash: '#security' })"
      />
    </form>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRouter, useRoute, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import axios from "axios"
import { createRegistration } from "@/services/api/services/registrations/registrations"
import { usePlans } from "@/services/api/services/plans/plans"
import { useAppConfig } from "@/composables/useAppConfig"
import { useToastsStore } from "@/stores/toasts"

const { t } = useI18n()
const router = useRouter()
const route = useRoute()
const toasts = useToastsStore()
const { config } = useAppConfig()

const { data: plans } = usePlans()

const domain = computed(() => config.value?.domain ?? "")

// `?plan=` is how the pricing table hands a plan over, and `free` is not one
// of the plans on offer — `accounts/new.html.erb` kept it in a hidden field
// rather than showing a select nobody could use.
const requestedPlan = computed(() => (typeof route.query.plan === "string" ? route.query.plan : null))
const fixedPlan = computed(() => (requestedPlan.value === "free" ? "free" : null))

const failed = ref<string | null>(null)

const schema = toTypedSchema(
  z
    .object({
      name: z.string({ message: t("signup.nameRequired") }).min(1, t("signup.nameRequired")),
      plan: z.string().min(1, t("signup.planRequired")),
      email: z
        .string({ message: t("validation.emailRequired") })
        .min(1, t("validation.emailRequired"))
        .email(t("validation.emailInvalid")),
      password: z
        .string({ message: t("validation.passwordRequired") })
        .min(8, t("signup.passwordTooShort")),
      passwordConfirmation: z.string().min(1, t("signup.passwordConfirmationRequired")),
      vatId: z.string().optional(),
      subdomain: z.string().optional(),
    })
    .refine((values) => values.password === values.passwordConfirmation, {
      path: ["passwordConfirmation"],
      message: t("signup.passwordMismatch"),
    }),
)

const { handleSubmit, errors, defineField, isSubmitting, setFieldValue } = useForm({
  validationSchema: schema,
  initialValues: { plan: "" },
})

const [name, nameAttrs] = defineField("name")
const [plan, planAttrs] = defineField("plan")
const [email, emailAttrs] = defineField("email")
const [password, passwordAttrs] = defineField("password")
const [passwordConfirmation, passwordConfirmationAttrs] = defineField("passwordConfirmation")
const [vatId, vatIdAttrs] = defineField("vatId")
const [subdomain, subdomainAttrs] = defineField("subdomain")

// The plan the visitor arrived with, or the cheapest one the table offers —
// the select cannot be empty, and the API insists on a plan.
watch(
  [plans, fixedPlan, requestedPlan],
  () => {
    if (plan.value) return

    const offered = plans.value?.find((one) => one.code === requestedPlan.value)

    setFieldValue("plan", fixedPlan.value ?? offered?.code ?? plans.value?.[0]?.code ?? "")
  },
  { immediate: true },
)

// ActiveModel names a nested user's attribute `users.email`; the field it
// belongs to here is `email`.
const FIELDS: Record<string, string> = {
  name: "name",
  subdomain: "subdomain",
  vat_id: "vatId",
  plan: "plan",
  "users.email": "email",
  "users.password": "password",
  "users.password_confirmation": "passwordConfirmation",
}

const onSubmit = handleSubmit(async (values, { setErrors }) => {
  failed.value = null

  try {
    await createRegistration({
      name: values.name,
      plan: values.plan,
      ...(values.vatId ? { vat_id: values.vatId } : {}),
      ...(values.subdomain ? { subdomain: values.subdomain } : {}),
      users_attributes: [
        {
          email: values.email,
          password: values.password,
          password_confirmation: values.passwordConfirmation,
        },
      ],
    })

    // Signing up does not sign in: the account's first user confirms their
    // address first, which is what the server-rendered screen said here too.
    toasts.push("success", t("signup.created"))
    await router.push({ name: "login" })
  } catch (error) {
    const data = axios.isAxiosError(error) ? error.response?.data : undefined
    const fields = (data as { errors?: Record<string, string[]> } | undefined)?.errors ?? {}
    const mapped: Record<string, string> = {}
    const rest: string[] = []

    for (const [attribute, messages] of Object.entries(fields)) {
      const field = FIELDS[attribute]

      if (field) mapped[field] = messages.join(", ")
      else rest.push(`${attribute} ${messages.join(", ")}`)
    }

    setErrors(mapped)
    failed.value = rest.length ? rest.join(" — ") : t("signup.failed")
  }
})

const FIELD =
  "block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-placeholder focus:border-field-focus focus:outline-none"
</script>

<template>
  <div class="mx-auto mt-[8%] w-full max-w-[300px] px-3 md:px-0">
    <h1 class="mb-2.5 text-center font-brand text-[30px] font-medium leading-tight">
      <RouterLink :to="{ name: 'dashboard' }" class="mb-2.5 block text-brand hover:no-underline">
        {{ t("brand") }}
      </RouterLink>
      <small class="block text-[65%] text-muted">{{ t("signup.title") }}</small>
    </h1>

    <form novalidate @submit="onSubmit">
      <div class="mb-[15px]">
        <input
          v-model="name"
          v-bind="nameAttrs"
          type="text"
          autocomplete="organization"
          :placeholder="t('signup.name')"
          data-test="name"
          :class="FIELD"
        />
        <p v-if="errors.name" data-test="name-error" class="mt-1 text-[13px] text-danger">
          {{ errors.name }}
        </p>
      </div>

      <div v-if="!fixedPlan && plans?.length" class="mb-[15px]">
        <select v-model="plan" v-bind="planAttrs" data-test="plan" :class="FIELD">
          <option v-for="one in plans" :key="one.id" :value="one.code">
            {{
              t("signup.planOption", {
                name: one.name,
                price: (one.price / 100).toFixed(2),
                per: t(`welcome.per.${one.interval ?? "month"}`),
              })
            }}
          </option>
        </select>
        <p v-if="errors.plan" data-test="plan-error" class="mt-1 text-[13px] text-danger">
          {{ errors.plan }}
        </p>
      </div>

      <hr class="my-5 border-t border-rule" />

      <div class="mb-[15px]">
        <input
          v-model="email"
          v-bind="emailAttrs"
          type="email"
          autocomplete="username"
          :placeholder="t('signup.email')"
          data-test="email"
          :class="FIELD"
        />
        <p v-if="errors.email" data-test="email-error" class="mt-1 text-[13px] text-danger">
          {{ errors.email }}
        </p>
      </div>

      <div class="mb-[15px]">
        <input
          v-model="password"
          v-bind="passwordAttrs"
          type="password"
          autocomplete="new-password"
          :placeholder="t('signup.password')"
          data-test="password"
          :class="FIELD"
        />
        <p v-if="errors.password" data-test="password-error" class="mt-1 text-[13px] text-danger">
          {{ errors.password }}
        </p>
      </div>

      <div class="mb-[15px]">
        <input
          v-model="passwordConfirmation"
          v-bind="passwordConfirmationAttrs"
          type="password"
          autocomplete="new-password"
          :placeholder="t('signup.passwordConfirmation')"
          data-test="password-confirmation"
          :class="FIELD"
        />
        <p
          v-if="errors.passwordConfirmation"
          data-test="password-confirmation-error"
          class="mt-1 text-[13px] text-danger"
        >
          {{ errors.passwordConfirmation }}
        </p>
      </div>

      <hr class="my-5 border-t border-rule" />

      <div class="mb-[15px]">
        <input
          v-model="vatId"
          v-bind="vatIdAttrs"
          type="text"
          :placeholder="t('signup.vatId')"
          data-test="vat-id"
          :class="FIELD"
        />
        <p v-if="errors.vatId" data-test="vat-id-error" class="mt-1 text-[13px] text-danger">
          {{ errors.vatId }}
        </p>
      </div>

      <!-- `.input-group`: the host the subdomain sits under is printed after
           the field rather than typed into it. -->
      <div class="mb-[15px]">
        <div class="flex">
          <input
            v-model="subdomain"
            v-bind="subdomainAttrs"
            type="text"
            autocapitalize="off"
            :placeholder="t('signup.subdomain')"
            data-test="subdomain"
            :class="[FIELD, 'rounded-r-none']"
          />
          <span
            class="flex items-center rounded-r border border-l-0 border-field-border bg-addon px-3 text-[16px] text-field"
          >
            .{{ domain }}
          </span>
        </div>
        <p v-if="errors.subdomain" data-test="subdomain-error" class="mt-1 text-[13px] text-danger">
          {{ errors.subdomain }}
        </p>
      </div>

      <p v-if="failed" data-test="signup-failed" class="mb-[10px] text-[14px] text-danger">
        {{ failed }}
      </p>

      <button
        type="submit"
        data-test="submit"
        :disabled="isSubmitting"
        class="block w-full rounded-md border border-brand-border bg-brand px-4 py-[10px] text-[18px] font-normal text-white hover:bg-brand-hover disabled:opacity-65"
      >
        {{ isSubmitting ? t("signup.submitting") : t("signup.submit") }}
      </button>

      <hr class="my-5 border-t border-rule" />

      <p class="mb-[10px] text-center text-[14px]">{{ t("signup.haveAccount") }}</p>
      <RouterLink
        :to="{ name: 'login' }"
        data-test="sign-in"
        class="block w-full rounded border border-field-border bg-surface px-3 py-[6px] text-center text-[14px] text-ink hover:bg-control-hover hover:no-underline"
      >
        {{ t("signup.backToLogin") }}
      </RouterLink>
    </form>
  </div>
</template>

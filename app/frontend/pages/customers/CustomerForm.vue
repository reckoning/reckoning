<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useForm } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import * as z from "zod"
import { useCustomer, useUpdateCustomer, useDestroyCustomer } from "@/services/api/services/customers/customers"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiNavTabs from "@/components/ui/UiNavTabs.vue"

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const id = String(route.params.id)
const tab = ref<"basic" | "email" | "offer">("basic")

const { data: customer, isPending, isError } = useCustomer(id)
const { mutateAsync: update, isPending: saving } = useUpdateCustomer()
const { mutateAsync: destroy } = useDestroyCustomer()

// An emptied number input hands over "", and coercing that yields 0 — which
// for `paymentDue` is not "no payment period" but "due immediately". Blank
// has to travel as null, which is why the API takes null for these two.
const nullableInt = z.preprocess(
  (value) => (value === "" || value === null || value === undefined ? null : Number(value)),
  z.number().int().nonnegative().nullable(),
)

// Mirrors CustomerInput. The API requires a name and nothing else, so the
// rest is optional here too rather than inventing rules the server does not
// have. Empty strings are sent as-is: the server stores them, which is how
// clearing a text field works.
const schema = toTypedSchema(
  z.object({
    name: z.string().min(1),
    address: z.string().optional(),
    country: z.string().optional(),
    email: z.string().email().or(z.literal("")).optional(),
    telefon: z.string().optional(),
    fax: z.string().optional(),
    website: z.string().optional(),
    paymentDue: nullableInt,
    weeklyHours: nullableInt,
    employmentDate: z.string().optional(),
    employmentEndDate: z.string().optional(),
    invoiceEmail: z.string().email().or(z.literal("")).optional(),
    invoiceEmailCc: z.string().optional(),
    invoiceEmailBcc: z.string().optional(),
    emailTemplate: z.string().optional(),
    offerDisclaimer: z.string().optional(),
  }),
)

const { defineField, handleSubmit, errors, setValues } = useForm({
  validationSchema: schema,
})

const [name, nameAttrs] = defineField("name")
const [address, addressAttrs] = defineField("address")
const [country, countryAttrs] = defineField("country")
const [email, emailAttrs] = defineField("email")
const [telefon, telefonAttrs] = defineField("telefon")
const [fax, faxAttrs] = defineField("fax")
const [website, websiteAttrs] = defineField("website")
const [paymentDue, paymentDueAttrs] = defineField("paymentDue")
const [weeklyHours, weeklyHoursAttrs] = defineField("weeklyHours")
const [employmentDate, employmentDateAttrs] = defineField("employmentDate")
const [employmentEndDate, employmentEndDateAttrs] = defineField("employmentEndDate")
const [invoiceEmail, invoiceEmailAttrs] = defineField("invoiceEmail")
const [invoiceEmailCc, invoiceEmailCcAttrs] = defineField("invoiceEmailCc")
const [invoiceEmailBcc, invoiceEmailBccAttrs] = defineField("invoiceEmailBcc")
const [emailTemplate, emailTemplateAttrs] = defineField("emailTemplate")
const [offerDisclaimer, offerDisclaimerAttrs] = defineField("offerDisclaimer")

// The record arrives after the first render, so the form fills itself in when
// the query resolves rather than on mount.
watch(
  customer,
  (loaded) => {
    if (!loaded) return

    setValues({
      name: loaded.name ?? "",
      address: loaded.address ?? "",
      country: loaded.country ?? "",
      email: loaded.email ?? "",
      telefon: loaded.telefon ?? "",
      fax: loaded.fax ?? "",
      website: loaded.website ?? "",
      paymentDue: loaded.paymentDue ?? undefined,
      weeklyHours: loaded.weeklyHours ?? undefined,
      employmentDate: loaded.employmentDate ?? "",
      employmentEndDate: loaded.employmentEndDate ?? "",
      invoiceEmail: loaded.invoiceEmail ?? "",
      invoiceEmailCc: loaded.invoiceEmailCc ?? "",
      invoiceEmailBcc: loaded.invoiceEmailBcc ?? "",
      emailTemplate: loaded.emailTemplate ?? "",
      offerDisclaimer: loaded.offerDisclaimer ?? "",
    })
  },
  { immediate: true },
)

// The tokens the invoice mailer actually substitutes. Anything else would be
// sent to the customer verbatim, so this list is not a place to improvise —
// it matches the gsubs in `app/mailers/invoice_mailer.rb` one for one. Clicking appends rather than
// inserting at the caret, which is not worth tracking for a paste helper.
const templateTokens = ["{date}", "{month}", "{project}", "{company}"] as const

function appendToken(token: string): void {
  emailTemplate.value = `${emailTemplate.value ?? ""}${token}`
}

const save = handleSubmit(async (values) => {
  try {
    await update({ id, data: values })
    toasts.push("success", t("customer.saved"))
  } catch {
    toasts.push("error", t("customer.saveFailed"))
  }
})

async function remove(): Promise<void> {
  if (!(await confirmDialog(t("customer.confirmDelete")))) return

  try {
    await destroy({ id })
    toasts.push("success", t("customer.deleted"))
    await router.push({ name: "customers" })
  } catch {
    toasts.push("error", t("customer.deleteFailed"))
  }
}

const tabs = computed(() => [
  { key: "basic" as const, label: t("customer.tabs.basic") },
  { key: "email" as const, label: t("customer.tabs.email") },
  { key: "offer" as const, label: t("customer.tabs.offer") },
])

// The `.form-control` shape, inline because these fields carry VeeValidate's
// own bindings rather than going through `UiInput`.
const FIELD =
  "block w-full rounded-bs border border-field-border bg-surface px-3 py-1.5 text-base leading-[1.428571429] text-field shadow-[inset_0_1px_1px_rgba(0,0,0,0.075)] placeholder:text-placeholder focus:border-field-focus focus:shadow-[inset_0_1px_1px_rgba(0,0,0,0.075),0_0_8px_rgba(102,175,233,0.6)] focus:outline-none"
</script>

<template>
  <div id="customer">
    <p v-if="isPending" data-test="loading">{{ t("customer.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("customer.loadFailed") }}</p>

    <div v-else>
      <div class="flex flex-wrap items-start gap-4">
        <h1 class="grow" data-test="customer-title">{{ customer?.name }}</h1>

        <div class="flex flex-wrap gap-2 max-md:w-full max-md:flex-col">
          <UiButton variant="danger" type="button" data-test="delete" @click="remove">
            {{ t("customer.delete") }}
          </UiButton>
          <RouterLink :to="{ name: 'customers' }" data-test="back">
            <UiButton class="max-md:w-full">{{ t("customer.back") }}</UiButton>
          </RouterLink>
        </div>
      </div>

      <div class="mt-4" data-test="tabs">
        <UiNavTabs :tabs="tabs.map((entry) => ({ key: entry.key, label: entry.label }))" :active="tab" @select="tab = $event as typeof tab" />
      </div>

      <form class="mt-4 max-w-3xl" @submit="save">
        <div v-show="tab === 'basic'">
          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.name") }}</span>
            <input v-model="name" v-bind="nameAttrs" type="text" data-test="name" :class="FIELD" />
            <span v-if="errors.name" data-test="name-error" class="mt-1 block text-danger-text">{{ errors.name }}</span>
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.address") }}</span>
            <textarea v-model="address" v-bind="addressAttrs" rows="3" data-test="address" :class="FIELD"></textarea>
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.country") }}</span>
            <input v-model="country" v-bind="countryAttrs" type="text" data-test="country" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.email") }}</span>
            <input v-model="email" v-bind="emailAttrs" type="email" data-test="email" :class="FIELD" />
            <span v-if="errors.email" data-test="email-error" class="mt-1 block text-danger-text">{{ errors.email }}</span>
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.telefon") }}</span>
            <input v-model="telefon" v-bind="telefonAttrs" type="text" data-test="telefon" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.fax") }}</span>
            <input v-model="fax" v-bind="faxAttrs" type="text" data-test="fax" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.website") }}</span>
            <input v-model="website" v-bind="websiteAttrs" type="text" data-test="website" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.paymentDue") }}</span>
            <input v-model="paymentDue" v-bind="paymentDueAttrs" type="number" min="0" data-test="payment-due" :class="FIELD" />
            <span v-if="errors.paymentDue" data-test="payment-due-error" class="mt-1 block text-danger-text">{{ errors.paymentDue }}</span>
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.employmentDate") }}</span>
            <input v-model="employmentDate" v-bind="employmentDateAttrs" type="date" data-test="employment-date" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.employmentEndDate") }}</span>
            <input v-model="employmentEndDate" v-bind="employmentEndDateAttrs" type="date" data-test="employment-end-date" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.weeklyHours") }}</span>
            <input v-model="weeklyHours" v-bind="weeklyHoursAttrs" type="number" min="0" data-test="weekly-hours" :class="FIELD" />
          </label>
        </div>

        <div v-show="tab === 'email'">
          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.invoiceEmail") }}</span>
            <input v-model="invoiceEmail" v-bind="invoiceEmailAttrs" type="email" data-test="invoice-email" :class="FIELD" />
            <span v-if="errors.invoiceEmail" data-test="invoice-email-error" class="mt-1 block text-danger-text">{{ errors.invoiceEmail }}</span>
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.invoiceEmailCc") }}</span>
            <input v-model="invoiceEmailCc" v-bind="invoiceEmailCcAttrs" type="text" data-test="invoice-email-cc" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.invoiceEmailBcc") }}</span>
            <input v-model="invoiceEmailBcc" v-bind="invoiceEmailBccAttrs" type="text" data-test="invoice-email-bcc" :class="FIELD" />
          </label>

          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.emailTemplate") }}</span>
            <textarea v-model="emailTemplate" v-bind="emailTemplateAttrs" rows="8" data-test="email-template" :class="[FIELD, 'font-mono text-small']"></textarea>
          </label>

          <div class="flex flex-wrap gap-2" data-test="template-tokens">
            <button
              v-for="token in templateTokens"
              :key="token"
              type="button"
              class="rounded border border-field-border bg-surface-muted px-2 py-1 text-left text-[12px]"
              :data-test="`token-${token.replace(/[{}]/g, '')}`"
              @click="appendToken(token)"
            >
              <code class="font-mono">{{ token }}</code>
              <span class="ml-2 text-muted">{{ t(`customer.tokens.${token.replace(/[{}]/g, "")}`) }}</span>
            </button>
          </div>
        </div>

        <div v-show="tab === 'offer'">
          <label class="mb-4 block">
            <span class="mb-1 inline-block font-bold">{{ t("customer.fields.offerDisclaimer") }}</span>
            <textarea v-model="offerDisclaimer" v-bind="offerDisclaimerAttrs" rows="6" data-test="offer-disclaimer" :class="FIELD"></textarea>
          </label>
        </div>

        <UiFormActions
          :save-label="t('customer.save')"
          :cancel-label="t('customer.cancel')"
          :busy="saving"
          @cancel="router.push({ name: 'customers' })"
        />
      </form>
    </div>
  </div>
</template>

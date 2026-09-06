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

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const id = String(route.params.id)
const tab = ref<"basic" | "email" | "offer">("basic")

const { data: customer, isPending, isError } = useCustomer(id)
const { mutateAsync: update, isPending: saving } = useUpdateCustomer()
const { mutateAsync: destroy } = useDestroyCustomer()

// Mirrors CustomerInput. The API requires a name and nothing else, so the
// rest is optional here too rather than inventing rules the server does not
// have. Empty strings are sent as-is: the server stores them, which is how
// clearing a field works.
const schema = toTypedSchema(
  z.object({
    name: z.string().min(1),
    address: z.string().optional(),
    country: z.string().optional(),
    email: z.string().email().or(z.literal("")).optional(),
    telefon: z.string().optional(),
    fax: z.string().optional(),
    website: z.string().optional(),
    paymentDue: z.coerce.number().int().nonnegative().optional(),
    weeklyHours: z.coerce.number().int().nonnegative().optional(),
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

// The tokens the mail template understands, lifted from the ERB form. Clicking
// one appends it rather than replacing the caret position — the caret is not
// worth tracking for a paste helper.
const templateTokens = ["{{customer}}", "{{invoice_ref}}", "{{invoice_date}}", "{{payment_due}}", "{{total}}"]

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
</script>

<template>
  <div class="p-4">
    <p v-if="isPending" data-test="loading">{{ t("customer.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("customer.loadFailed") }}</p>

    <div v-else>
      <div class="mb-4 flex items-center justify-between">
        <h1 class="text-[24px] font-medium" data-test="customer-title">{{ customer?.name }}</h1>

        <div class="flex gap-2">
          <RouterLink :to="{ name: 'customers' }" class="text-sm underline" data-test="back">
            {{ t("customer.back") }}
          </RouterLink>
          <button type="button" class="text-sm text-danger underline" data-test="delete" @click="remove">
            {{ t("customer.delete") }}
          </button>
        </div>
      </div>

      <nav class="mb-4 flex gap-4 border-b border-rule" data-test="tabs">
        <button
          v-for="entry in tabs"
          :key="entry.key"
          type="button"
          class="border-b-2 pb-2 text-sm"
          :class="tab === entry.key ? 'border-brand text-brand' : 'border-transparent text-muted'"
          :data-test="`tab-${entry.key}`"
          @click="tab = entry.key"
        >
          {{ entry.label }}
        </button>
      </nav>

      <form class="max-w-2xl" @submit="save">
        <div v-show="tab === 'basic'" class="flex flex-col gap-3">
          <label class="text-sm">
            {{ t("customer.fields.name") }}
            <input v-model="name" v-bind="nameAttrs" type="text" data-test="name" class="mt-1 block w-full rounded border border-field-border p-2" />
            <span v-if="errors.name" data-test="name-error" class="text-[13px] text-danger">{{ errors.name }}</span>
          </label>

          <label class="text-sm">
            {{ t("customer.fields.address") }}
            <textarea v-model="address" v-bind="addressAttrs" rows="3" data-test="address" class="mt-1 block w-full rounded border border-field-border p-2"></textarea>
          </label>

          <label class="text-sm">
            {{ t("customer.fields.country") }}
            <input v-model="country" v-bind="countryAttrs" type="text" data-test="country" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.email") }}
            <input v-model="email" v-bind="emailAttrs" type="email" data-test="email" class="mt-1 block w-full rounded border border-field-border p-2" />
            <span v-if="errors.email" data-test="email-error" class="text-[13px] text-danger">{{ errors.email }}</span>
          </label>

          <label class="text-sm">
            {{ t("customer.fields.telefon") }}
            <input v-model="telefon" v-bind="telefonAttrs" type="text" data-test="telefon" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.fax") }}
            <input v-model="fax" v-bind="faxAttrs" type="text" data-test="fax" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.website") }}
            <input v-model="website" v-bind="websiteAttrs" type="text" data-test="website" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.paymentDue") }}
            <input v-model="paymentDue" v-bind="paymentDueAttrs" type="number" min="0" data-test="payment-due" class="mt-1 block w-full rounded border border-field-border p-2" />
            <span v-if="errors.paymentDue" data-test="payment-due-error" class="text-[13px] text-danger">{{ errors.paymentDue }}</span>
          </label>

          <label class="text-sm">
            {{ t("customer.fields.employmentDate") }}
            <input v-model="employmentDate" v-bind="employmentDateAttrs" type="date" data-test="employment-date" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.employmentEndDate") }}
            <input v-model="employmentEndDate" v-bind="employmentEndDateAttrs" type="date" data-test="employment-end-date" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.weeklyHours") }}
            <input v-model="weeklyHours" v-bind="weeklyHoursAttrs" type="number" min="0" data-test="weekly-hours" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>
        </div>

        <div v-show="tab === 'email'" class="flex flex-col gap-3">
          <label class="text-sm">
            {{ t("customer.fields.invoiceEmail") }}
            <input v-model="invoiceEmail" v-bind="invoiceEmailAttrs" type="email" data-test="invoice-email" class="mt-1 block w-full rounded border border-field-border p-2" />
            <span v-if="errors.invoiceEmail" data-test="invoice-email-error" class="text-[13px] text-danger">{{ errors.invoiceEmail }}</span>
          </label>

          <label class="text-sm">
            {{ t("customer.fields.invoiceEmailCc") }}
            <input v-model="invoiceEmailCc" v-bind="invoiceEmailCcAttrs" type="text" data-test="invoice-email-cc" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.invoiceEmailBcc") }}
            <input v-model="invoiceEmailBcc" v-bind="invoiceEmailBccAttrs" type="text" data-test="invoice-email-bcc" class="mt-1 block w-full rounded border border-field-border p-2" />
          </label>

          <label class="text-sm">
            {{ t("customer.fields.emailTemplate") }}
            <textarea v-model="emailTemplate" v-bind="emailTemplateAttrs" rows="8" data-test="email-template" class="mt-1 block w-full rounded border border-field-border p-2 font-mono text-[13px]"></textarea>
          </label>

          <div class="flex flex-wrap gap-2" data-test="template-tokens">
            <button
              v-for="token in templateTokens"
              :key="token"
              type="button"
              class="rounded border border-field-border bg-surface-muted px-2 py-1 font-mono text-[12px]"
              @click="appendToken(token)"
            >
              {{ token }}
            </button>
          </div>
        </div>

        <div v-show="tab === 'offer'" class="flex flex-col gap-3">
          <label class="text-sm">
            {{ t("customer.fields.offerDisclaimer") }}
            <textarea v-model="offerDisclaimer" v-bind="offerDisclaimerAttrs" rows="6" data-test="offer-disclaimer" class="mt-1 block w-full rounded border border-field-border p-2"></textarea>
          </label>
        </div>

        <button
          type="submit"
          class="mt-4 rounded-md border border-brand-border bg-brand px-4 py-2 text-white hover:bg-brand-hover disabled:opacity-60"
          :disabled="saving"
          data-test="submit"
        >
          {{ t("customer.save") }}
        </button>
      </form>
    </div>
  </div>
</template>

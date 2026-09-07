<script setup lang="ts">
import { computed, ref } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useQueryClient } from "@tanstack/vue-query"
import {
  useInvoice,
  useChargeInvoice,
  usePayInvoice,
  useSendInvoiceMail,
  useSendInvoiceTestMail,
  useDestroyInvoice,
  getInvoiceQueryKey,
} from "@/services/api/services/invoices/invoices"
import PdfViewer from "@/components/PdfViewer.vue"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()
const queryClient = useQueryClient()

const id = String(route.params.id)

const { data: invoice, isPending, isError } = useInvoice(id)
const { mutateAsync: charge } = useChargeInvoice()
const { mutateAsync: pay } = usePayInvoice()
const { mutateAsync: sendMail } = useSendInvoiceMail()
const { mutateAsync: sendTestMail } = useSendInvoiceTestMail()
const { mutateAsync: destroy } = useDestroyInvoice()

const testMailAddress = ref("")
const busy = ref(false)

// What this user may do, as the endpoint reports it. Deriving it from the
// state was wrong twice over: an expired trial reads everything and writes
// nothing, and `editable` is a property of the record rather than a
// permission. Both cases offered buttons the API answers with 403.
const abilities = computed(() => invoice.value?.abilities)

// `invoice.timers` is `through: :positions`, so a timesheet exists exactly
// when some position was built from tracked time.
const hasTimesheet = computed(() =>
  (invoice.value?.positions ?? []).some((position) => (position.timerIds ?? []).length > 0),
)

const overdue = computed(() => {
  const due = invoice.value?.paymentDueDate

  return invoice.value?.state === "charged" && !!due && new Date(`${due.slice(0, 10)}T00:00:00Z`) < new Date()
})

// The filename segment is decorative: `send_data` sets the download name from
// the record, and the preview is fetched by pdf.js either way.
const invoicePdf = computed(() => `/invoices/${id}/pdf/invoice.pdf`)
const timesheetPdf = computed(() => `/invoices/${id}/timesheet-pdf/timesheet.pdf`)

const money = computed(
  () => new Intl.NumberFormat(locale.value, {style: "currency", currency: "EUR"}),
)
const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, {dateStyle: "medium", timeZone: "UTC"}),
)

function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

async function refresh(): Promise<void> {
  await queryClient.invalidateQueries({queryKey: getInvoiceQueryKey(id)})
}

async function run(action: () => Promise<unknown>, message: string): Promise<void> {
  busy.value = true

  try {
    await action()
    toasts.push("success", message)
    await refresh()
  } catch {
    toasts.push("error", t("invoice.actionFailed"))
  } finally {
    busy.value = false
  }
}

// The confirm happens outside `run`: declining is not a failed action, and
// throwing to get out of it produced a "that did not work" toast after the
// user had deliberately said no.
async function chargeInvoice(): Promise<void> {
  const confirmed = await confirmDialog(
    invoice.value?.sendable ? t("invoice.confirmChargeMail") : t("invoice.confirmCharge"),
  )
  if (!confirmed) return

  await run(() => charge({id}), t("invoice.charged"))
}

const payInvoice = () => run(() => pay({id}), t("invoice.paid"))
const mailInvoice = () => run(() => sendMail({id}), t("invoice.mailed"))

const mailTest = () =>
  run(
    () => sendTestMail({id, data: {email: testMailAddress.value}}),
    t("invoice.testMailed"),
  )

async function removeInvoice(): Promise<void> {
  if (!(await confirmDialog(t("invoice.confirmDelete")))) return

  try {
    await destroy({id})
    toasts.push("success", t("invoice.deleted"))
    await router.push({name: "invoices"})
  } catch {
    toasts.push("error", t("invoice.deleteFailed"))
  }
}
</script>

<template>
  <div class="p-4">
    <p v-if="isPending" data-test="loading">{{ t("invoice.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("invoice.loadFailed") }}</p>

    <div v-else-if="invoice">
      <div class="mb-4 flex flex-wrap items-center gap-3">
        <h1 class="text-[24px] font-medium" data-test="invoice-title">
          {{ t("invoice.title", { ref: invoice.refNumber ?? invoice.ref }) }}
        </h1>

        <span v-if="overdue" class="rounded border border-danger px-2 py-1 text-[13px] text-danger" data-test="overdue">
          {{ t("invoice.overdue") }}
        </span>

        <span class="rounded border border-rule px-2 py-1 text-[13px] text-muted" data-test="state">
          {{ t(`invoices.states.${invoice.state}`) }}
        </span>

        <div class="ml-auto flex flex-wrap gap-2">
          <button
            v-if="abilities?.charge"
            type="button"
            class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover disabled:opacity-60"
            :disabled="busy"
            data-test="charge"
            @click="chargeInvoice"
          >
            {{ t("invoice.charge") }}
          </button>

          <button
            v-if="abilities?.pay"
            type="button"
            class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover disabled:opacity-60"
            :disabled="busy"
            data-test="pay"
            @click="payInvoice"
          >
            {{ t("invoice.pay") }}
          </button>

          <RouterLink :to="{ name: 'invoices' }" class="rounded border border-field-border px-4 py-2 text-sm" data-test="back">
            {{ t("invoice.back") }}
          </RouterLink>
        </div>
      </div>

      <dl class="mb-4 grid grid-cols-2 gap-2 text-sm sm:grid-cols-4" data-test="facts">
        <div>
          <dt class="text-muted">{{ t("invoice.fields.customer") }}</dt>
          <dd>{{ invoice.customerName }}</dd>
        </div>
        <div>
          <dt class="text-muted">{{ t("invoice.fields.date") }}</dt>
          <dd class="tabular-nums">{{ formatDate(invoice.date) }}</dd>
        </div>
        <div>
          <dt class="text-muted">{{ t("invoice.fields.paymentDueDate") }}</dt>
          <dd class="tabular-nums">{{ formatDate(invoice.paymentDueDate) }}</dd>
        </div>
        <div>
          <dt class="text-muted">{{ t("invoice.fields.value") }}</dt>
          <dd class="tabular-nums" data-test="value">{{ money.format(Number(invoice.value ?? 0)) }}</dd>
        </div>
      </dl>

      <div class="mb-6 flex flex-wrap gap-3 text-sm">
        <a :href="invoicePdf" target="_blank" class="text-brand underline" data-test="invoice-pdf">
          {{ t("invoice.downloadInvoice") }}
        </a>
        <a v-if="hasTimesheet" :href="timesheetPdf" target="_blank" class="text-brand underline" data-test="timesheet-pdf">
          {{ t("invoice.downloadTimesheet") }}
        </a>
        <RouterLink
          v-if="abilities?.update"
          :to="{ name: 'invoice-edit', params: { id } }"
          class="text-brand underline"
          data-test="edit"
        >
          {{ t("invoice.edit") }}
        </RouterLink>
        <button
          v-if="abilities?.sendMail"
          type="button"
          class="text-brand underline disabled:opacity-60"
          :disabled="busy"
          data-test="send-mail"
          @click="mailInvoice"
        >
          {{ t("invoice.sendMail") }}
        </button>
        <button
          v-if="abilities?.destroy"
          type="button"
          class="text-danger underline"
          data-test="delete"
          @click="removeInvoice"
        >
          {{ t("invoice.delete") }}
        </button>
      </div>

      <table class="mb-6 w-full border-collapse text-sm" data-test="positions">
        <thead>
          <tr class="border-b border-rule-strong text-left">
            <th class="px-2 py-2">{{ t("invoice.positions.description") }}</th>
            <th class="px-2 py-2 text-right">{{ t("invoice.positions.hours") }}</th>
            <th class="px-2 py-2 text-right">{{ t("invoice.positions.rate") }}</th>
            <th class="px-2 py-2 text-right">{{ t("invoice.positions.value") }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="position in invoice.positions ?? []" :key="position.id" class="border-b border-rule">
            <td class="px-2 py-2">{{ position.description }}</td>
            <td class="px-2 py-2 text-right tabular-nums">{{ position.hours }}</td>
            <td class="px-2 py-2 text-right tabular-nums">
              {{ position.rate ? money.format(Number(position.rate)) : "" }}
            </td>
            <td class="px-2 py-2 text-right tabular-nums">
              {{ position.value ? money.format(Number(position.value)) : "" }}
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Only when a mail could actually go out: without an invoice email
           template `InvoiceMailer#send_mail` gsubs a missing string and the
           job dies, after the form has already reported success. -->
      <form
        v-if="invoice.sendable"
        class="mb-6 flex max-w-md items-end gap-2"
        data-test="test-mail-form"
        @submit.prevent="mailTest"
      >
        <label class="grow text-sm">
          {{ t("invoice.testMail") }}
          <input
            v-model="testMailAddress"
            type="email"
            required
            data-test="test-mail-email"
            class="mt-1 block w-full rounded border border-field-border p-2"
          />
        </label>
        <button
          type="submit"
          class="rounded border border-field-border px-3 py-2 text-sm disabled:opacity-60"
          :disabled="busy"
          data-test="send-test-mail"
        >
          {{ t("invoice.send") }}
        </button>
      </form>

      <section class="flex flex-col gap-6">
        <div>
          <h2 class="mb-2 text-base font-semibold">{{ t("invoice.preview") }}</h2>
          <PdfViewer :src="invoicePdf" data-test="invoice-preview" />
        </div>

        <div v-if="hasTimesheet">
          <h2 class="mb-2 text-base font-semibold">{{ t("invoice.timesheetPreview") }}</h2>
          <PdfViewer :src="timesheetPdf" data-test="timesheet-preview" />
        </div>
      </section>
    </div>
  </div>
</template>

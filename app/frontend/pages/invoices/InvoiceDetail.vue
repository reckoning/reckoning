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
import UiButton from "@/components/ui/UiButton.vue"
import UiInput from "@/components/ui/UiInput.vue"
import UiInputGroup from "@/components/ui/UiInputGroup.vue"
import UiLabel from "@/components/ui/UiLabel.vue"
import UiListGroup from "@/components/ui/UiListGroup.vue"
import UiListGroupItem from "@/components/ui/UiListGroupItem.vue"
import UiNavTabs from "@/components/ui/UiNavTabs.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

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

// The preview was a tab strip: the invoice, and the timesheet beside it when
// there is one.
const tab = ref<"invoice" | "timesheet">("invoice")

const tabs = computed(() => {
  const entries = [{key: "invoice", label: t("invoice.preview")}]

  if (hasTimesheet.value) entries.push({key: "timesheet", label: t("invoice.timesheetPreview")})

  return entries
})

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
  <div id="invoice">
    <p v-if="isPending" data-test="loading">{{ t("invoice.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("invoice.loadFailed") }}</p>

    <template v-else-if="invoice">
      <div class="flex flex-wrap items-start gap-4">
        <h1 class="grow" data-test="invoice-title">
          {{ t("invoice.title", { ref: invoice.refNumber ?? invoice.ref }) }}
          <small v-if="overdue" class="text-[65%]">
            <UiLabel variant="danger" data-test="overdue">{{ t("invoice.overdue") }}</UiLabel>
          </small>
          <small class="ml-1 text-[65%]">
            <UiLabel :variant="invoice.state === 'paid' ? 'success' : invoice.state === 'created' ? 'default' : 'primary'" data-test="state">
              {{ t(`invoices.states.${invoice.state}`) }}
            </UiLabel>
          </small>
        </h1>

        <div class="flex flex-wrap gap-2 max-md:w-full max-md:flex-col">
          <UiButton
            v-if="abilities?.charge"
            variant="primary"
            :disabled="busy"
            data-test="charge"
            @click="chargeInvoice"
          >
            {{ t("invoice.charge") }}
          </UiButton>

          <UiButton
            v-if="abilities?.pay"
            variant="primary"
            :disabled="busy"
            data-test="pay"
            @click="payInvoice"
          >
            {{ t("invoice.pay") }}
          </UiButton>

          <RouterLink :to="{ name: 'invoices' }" data-test="back">
            <UiButton class="max-md:w-full">{{ t("invoice.back") }}</UiButton>
          </RouterLink>
        </div>
      </div>

      <div class="mt-4 grid gap-4 md:grid-cols-3">
        <!-- The preview, which is where the invoice's own numbers are: the
             server-rendered screen showed the document rather than repeating
             it beside itself. -->
        <div class="md:col-span-2">
          <UiNavTabs :tabs="tabs" :active="tab" @select="tab = $event as 'invoice' | 'timesheet'" />

          <div class="border border-t-0 border-rule-strong p-4">
            <PdfViewer v-if="tab === 'invoice'" :src="invoicePdf" data-test="invoice-preview" />
            <PdfViewer v-else :src="timesheetPdf" data-test="timesheet-preview" />
          </div>
        </div>

        <div class="md:pt-10">
          <UiPanel :title="t('invoice.downloads')">
            <UiListGroup>
              <UiListGroupItem interactive>
                <a :href="invoicePdf" target="_blank" data-test="invoice-pdf">
                  {{ t("invoice.downloadInvoice") }}
                </a>
              </UiListGroupItem>
              <UiListGroupItem v-if="hasTimesheet" interactive>
                <a :href="timesheetPdf" target="_blank" data-test="timesheet-pdf">
                  {{ t("invoice.downloadTimesheet") }}
                </a>
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>

          <UiPanel :title="t('invoice.actions')">
            <UiListGroup>
              <UiListGroupItem v-if="abilities?.update" interactive>
                <RouterLink :to="{ name: 'invoice-edit', params: { id } }" data-test="edit">
                  {{ t("invoice.edit") }}
                </RouterLink>
              </UiListGroupItem>

              <UiListGroupItem v-if="abilities?.sendMail" interactive>
                <button type="button" :disabled="busy" data-test="send-mail" @click="mailInvoice">
                  {{ t("invoice.sendMail") }}
                </button>
              </UiListGroupItem>

              <UiListGroupItem v-if="abilities?.destroy" interactive>
                <button type="button" class="text-danger-text" data-test="delete" @click="removeInvoice">
                  {{ t("invoice.delete") }}
                </button>
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>

          <!-- Only when a mail could actually go out: without an invoice email
               template `InvoiceMailer#send_mail` gsubs a missing string and
               the job dies, after the form has already reported success. -->
          <UiPanel v-if="invoice.sendable" :title="t('invoice.testMail')">
            <template #body>
              <form data-test="test-mail-form" @submit.prevent="mailTest">
                <UiInputGroup>
                  <UiInput
                    v-model="testMailAddress"
                    type="email"
                    required
                    :placeholder="t('invoice.testMailPlaceholder')"
                    data-test="test-mail-email"
                  />
                  <template #button>
                    <UiButton variant="primary" :disabled="busy" data-test="send-test-mail">
                      {{ t("invoice.send") }}
                    </UiButton>
                  </template>
                </UiInputGroup>
              </form>
            </template>
          </UiPanel>
        </div>
      </div>
    </template>
  </div>
</template>

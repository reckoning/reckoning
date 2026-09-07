<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useInvoice, useCreateInvoice, useUpdateInvoice } from "@/services/api/services/invoices/invoices"
import { useProjects, useProject } from "@/services/api/services/projects/projects"
import { useUninvoicedTimers } from "@/services/api/services/timers/timers"
import { useAccount } from "@/services/api/services/account/account"
import { useToastsStore } from "@/stores/toasts"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiInput from "@/components/ui/UiInput.vue"
import UiInputGroup from "@/components/ui/UiInputGroup.vue"
import UiPanel from "@/components/ui/UiPanel.vue"

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()

const id = computed(() => (route.params.id ? String(route.params.id) : undefined))
const editing = computed(() => id.value !== undefined)

const { data: invoice, isPending, isError } = useInvoice(id.value ?? "", {
  query: { enabled: editing.value },
})
const { data: projects } = useProjects()
const { data: account } = useAccount()
const { mutateAsync: create } = useCreateInvoice()
const { mutateAsync: update } = useUpdateInvoice()

// A row is either typed by hand or built from tracked time. The second kind
// owns its hours — they are the sum of the timers behind it — which is why the
// ERB form had two partials for one thing.
interface Row {
  id?: string
  description: string
  rate: string
  hours: string
  value: string
  timerIds: string[]
  // Set when the project filled the rate in rather than the user. Comparing
  // the rate against the project's would mistake a hand-typed rate that
  // happens to match for one this form wrote.
  rateFromProject: boolean
  destroyed: boolean
}

const projectId = ref(String(route.query.project_id ?? ""))
const date = ref("")
const deliveryDate = ref("")
const paymentDueDate = ref("")
const ref_ = ref("")
const rows = ref<Row[]>([])
const busy = ref(false)
const filledFrom = ref<string | undefined>()

const { data: project } = useProject(projectId, {
  query: { enabled: computed(() => projectId.value !== "") },
})

const projectRate = computed(() => project.value?.rate ?? "")

// The ERB `new` action refused to render without an account address — an
// invoice cannot be issued without one — and refused a third invoice on a
// demo deployment. Both guards lived in the action that just went away.
const missingAddress = computed(() => !editing.value && !(account.value?.address ?? "").trim())
const limitReached = computed(() => !editing.value && account.value?.invoiceLimitReached === true)
const blocked = computed(() => missingAddress.value || limitReached.value)

function emptyRow(): Row {
  return {description: "", rate: "", hours: "", value: "", timerIds: [], rateFromProject: false, destroyed: false}
}

watch(
  invoice,
  (loaded) => {
    if (!loaded || filledFrom.value === loaded.id) return

    filledFrom.value = loaded.id
    projectId.value = loaded.projectId ?? ""
    date.value = (loaded.date ?? "").slice(0, 10)
    deliveryDate.value = (loaded.deliveryDate ?? "").slice(0, 10)
    paymentDueDate.value = (loaded.paymentDueDate ?? "").slice(0, 10)
    ref_.value = loaded.ref === null || loaded.ref === undefined ? "" : String(loaded.ref)
    rows.value = (loaded.positions ?? []).map((position) => ({
      id: position.id,
      description: position.description ?? "",
      rate: position.rate ?? "",
      hours: position.hours ?? "",
      value: position.value ?? "",
      timerIds: position.timerIds ?? [],
      // A saved rate is data, whoever typed it.
      rateFromProject: false,
      destroyed: false,
    }))
  },
  { immediate: true },
)

// Rows built from tracked time belong to the project they came from: the
// invoice takes its customer and its rate from the project, and the server
// refuses time from anywhere else. Switching projects therefore takes them
// with it — a saved one is marked for destruction rather than dropped, so the
// server removes it — while rows typed by hand stay.
watch(projectId, (next, previous) => {
  if (previous === "" || next === previous) return

  rows.value = rows.value.filter((row) => {
    if (row.timerIds.length === 0) return true
    if (!row.id) return false

    row.destroyed = true
    row.timerIds = []

    return true
  })

  if (rows.value.every((row) => row.destroyed)) rows.value.push(emptyRow())
})

// What the ERB did through `oldProjectRate`: a rate the project filled in
// follows the new project. A rate typed by hand stays put, which is why the
// rows carry the flag rather than being compared against the old rate.
//
// Keyed on the record rather than on its rate: the query blanks out while the
// newly picked project loads, and a blank rate is indistinguishable from a
// project that has none — which would leave the old project's rate in place.
watch(project, (loaded) => {
  if (!loaded || loaded.id !== projectId.value) return

  const rate = String(loaded.rate ?? "")

  for (const row of rows.value) {
    // A row typed before the project's rate arrived is waiting for it: hours
    // and no rate. Without this the rate stays empty for good, because
    // `recalculate` only ever ran while the query was still in flight.
    const waiting = !row.id && row.hours !== "" && row.rate === ""

    if (!row.rateFromProject && !waiting) continue

    row.rate = rate
    // Nothing to derive a value from, so a stale value goes rather than
    // being billed.
    if (rate === "") row.value = ""
    row.rateFromProject = rate !== ""
    recalculate(row)
  }
})

// A new invoice starts with one empty row, the way `new` did.
watch(
  editing,
  (isEditing) => {
    if (!isEditing && rows.value.length === 0) rows.value = [emptyRow()]
  },
  { immediate: true },
)

const visibleRows = computed(() =>
  rows.value.map((row, index) => ({row, index})).filter(({row}) => !row.destroyed),
)

// What the ERB did on every keystroke: hours imply a rate, and a rate with
// hours implies the value. A row with no hours keeps its value editable —
// that is a flat price.
function recalculate(row: Row): void {
  if (row.hours === "") return

  if (row.rate === "") {
    row.rate = String(projectRate.value ?? "")
    row.rateFromProject = row.rate !== ""
  }

  if (row.rate !== "") row.value = String(Number(row.hours) * Number(row.rate))
}

// Typing in the rate field makes the rate the user's, so a later project
// change leaves it alone.
function rateTyped(row: Row): void {
  row.rateFromProject = false
  recalculate(row)
}

function addRow(): void {
  rows.value.push(emptyRow())
}

function removeRow(index: number): void {
  const row = rows.value[index]

  if (row.id) {
    row.destroyed = true
    return
  }

  rows.value.splice(index, 1)
}

const total = computed(() =>
  visibleRows.value.reduce((sum, {row}) => sum + Number(row.value || 0), 0),
)

// The picker behind "generate positions": every uninvoiced timer of the
// project that is not already on this invoice, grouped by task, because one
// task becomes one position.
const pickerOpen = ref(false)
const linkedTimerIds = computed(() => rows.value.flatMap((row) => row.timerIds))

const { data: uninvoiced, isFetching: loadingTimers } = useUninvoicedTimers(
  computed(() => ({projectId: projectId.value, timerIds: linkedTimerIds.value})),
  {query: {enabled: computed(() => pickerOpen.value && projectId.value !== "")}},
)

const candidates = computed(() => {
  const tasks = new Map<string, {taskId: string; name: string; hours: number; timerIds: string[]}>()

  for (const timer of uninvoiced.value ?? []) {
    const key = timer.taskId
    const entry = tasks.get(key) ?? {taskId: key, name: timer.taskName ?? "", hours: 0, timerIds: []}

    entry.hours += Number(timer.value ?? 0)
    entry.timerIds.push(timer.id)
    tasks.set(key, entry)
  }

  return [...tasks.values()].sort((a, b) => a.name.localeCompare(b.name))
})

const picked = ref<string[]>([])

function openPicker(): void {
  if (projectId.value === "") {
    toasts.push("error", t("invoiceForm.pickProjectFirst"))
    return
  }

  picked.value = []
  pickerOpen.value = true
}

function takePicked(): void {
  for (const candidate of candidates.value) {
    if (!picked.value.includes(candidate.taskId)) continue

    const row: Row = {
      description: candidate.name,
      rate: String(projectRate.value ?? ""),
      hours: String(candidate.hours),
      value: "",
      timerIds: candidate.timerIds,
      rateFromProject: String(projectRate.value ?? "") !== "",
      destroyed: false,
    }
    recalculate(row)
    rows.value.push(row)
  }

  pickerOpen.value = false
}

const money = computed(
  () => new Intl.NumberFormat(locale.value, {style: "currency", currency: "EUR"}),
)

function positionsAttributes() {
  return rows.value
    .filter((row) => row.id || row.description.trim() !== "" || row.value !== "")
    .map((row) => ({
      ...(row.id ? {id: row.id} : {}),
      description: row.description,
      hours: row.hours === "" ? null : row.hours,
      rate: row.rate === "" ? null : row.rate,
      value: row.value === "" ? null : row.value,
      timer_ids: row.timerIds,
      ...(row.destroyed ? {_destroy: true} : {}),
    }))
}

async function save(): Promise<void> {
  busy.value = true

  const data = {
    project_id: projectId.value || undefined,
    date: date.value || null,
    delivery_date: deliveryDate.value || null,
    payment_due_date: paymentDueDate.value || null,
    ref: ref_.value === "" ? null : Number(ref_.value),
    positions_attributes: positionsAttributes(),
  }

  try {
    const saved = editing.value
      ? await update({id: id.value as string, data})
      : await create({data})

    toasts.push("success", editing.value ? t("invoiceForm.saved") : t("invoiceForm.created"))
    await router.push({name: "invoice", params: {id: saved.id}})
  } catch {
    toasts.push("error", t("invoiceForm.saveFailed"))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div id="invoice-form">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="invoice-form-title">
        {{ editing ? t("invoiceForm.editTitle") : t("invoiceForm.newTitle") }}
      </h1>

      <div class="max-md:w-full">
        <RouterLink :to="{ name: 'invoices' }" data-test="back">
          <UiButton class="max-md:w-full">{{ t("invoiceForm.back") }}</UiButton>
        </RouterLink>
      </div>
    </div>

    <p v-if="editing && isPending" class="mt-4" data-test="loading">{{ t("invoiceForm.loading") }}</p>

    <p v-else-if="editing && isError" class="mt-4" data-test="load-failed">
      {{ t("invoiceForm.loadFailed") }}
    </p>

    <UiAlert v-else-if="missingAddress" variant="warning" class="mt-4" data-test="missing-address">
      {{ t("invoiceForm.missingAddress") }}
      <a href="/settings#address" data-test="account-settings">{{ t("invoiceForm.toSettings") }}</a>
    </UiAlert>

    <UiAlert v-else-if="limitReached" variant="warning" class="mt-4" data-test="limit-reached">
      {{ t("invoices.limitReached") }}
    </UiAlert>

    <form v-else class="mt-4" @submit.prevent="save">
      <div class="grid gap-4 md:grid-cols-3">
        <UiInput v-model="projectId" as="select" data-test="project">
          <option value="">{{ t("invoiceForm.fields.noProject") }}</option>
          <option v-for="entry in projects ?? []" :key="entry.id" :value="entry.id">
            {{ entry.label ?? entry.name }}
          </option>
        </UiInput>

        <UiInputGroup :addon="t('invoiceForm.fields.date')">
          <UiInput v-model="date" type="date" data-test="date" />
        </UiInputGroup>

        <UiInputGroup :addon="t('invoiceForm.fields.ref')">
          <UiInput v-model="ref_" type="number" data-test="ref" />
        </UiInputGroup>

        <UiInputGroup :addon="t('invoiceForm.fields.deliveryDate')">
          <UiInput v-model="deliveryDate" type="date" data-test="delivery-date" />
        </UiInputGroup>

        <UiInputGroup :addon="t('invoiceForm.fields.paymentDueDate')">
          <UiInput v-model="paymentDueDate" type="date" data-test="payment-due-date" />
        </UiInputGroup>
      </div>

      <UiPanel class="mt-5" :title="t('invoiceForm.positions')">
        <template #body>
          <div class="flex flex-col gap-2" data-test="positions">
            <div
              v-for="{ row, index } in visibleRows"
              :key="row.id ?? `new-${index}`"
              class="grid grid-cols-12 items-start gap-2"
            >
              <div class="col-span-12 md:col-span-5">
                <UiInput
                  v-model="row.description"
                  :placeholder="t('invoiceForm.fields.description')"
                  :data-test="`position-description-${index}`"
                />
              </div>

              <div class="col-span-4 md:col-span-2">
                <UiInputGroup :addon="t('invoiceForm.fields.rateAddon')">
                  <UiInput
                    v-model="row.rate"
                    type="number"
                    step="0.01"
                    class="text-right"
                    :data-test="`position-rate-${index}`"
                    @input="rateTyped(row)"
                  />
                </UiInputGroup>
              </div>

              <!-- Hours belong to the timers behind the row, so a generated
                   one shows them and does not offer them for editing. -->
              <div class="col-span-4 md:col-span-2">
                <UiInputGroup v-if="row.timerIds.length === 0" :addon="t('invoiceForm.fields.hoursAddon')">
                  <UiInput
                    v-model="row.hours"
                    type="number"
                    step="0.01"
                    class="text-right"
                    :data-test="`position-hours-${index}`"
                    @input="recalculate(row)"
                  />
                </UiInputGroup>
                <div v-else class="py-1.5 text-right tabular-nums" :data-test="`position-hours-fixed-${index}`">
                  {{ row.hours }} {{ t("invoiceForm.fields.hoursAddon") }}
                </div>
              </div>

              <div class="col-span-4 md:col-span-2">
                <UiInputGroup v-if="row.hours === ''">
                  <UiInput
                    v-model="row.value"
                    type="number"
                    step="0.01"
                    class="text-right"
                    :data-test="`position-value-${index}`"
                  />
                  <template #addon>€</template>
                </UiInputGroup>
                <div v-else class="py-1.5 text-right tabular-nums" :data-test="`position-value-computed-${index}`">
                  {{ row.value }}
                </div>
              </div>

              <div class="col-span-12 md:col-span-1 md:text-right">
                <UiButton
                  type="button"
                  variant="danger"
                  class="max-md:w-full"
                  :data-test="`position-remove-${index}`"
                  @click="removeRow(index)"
                >
                  ×
                </UiButton>
              </div>
            </div>
          </div>

          <div class="mt-4 flex flex-wrap items-center gap-2">
            <UiButton type="button" data-test="add-position" @click="addRow">
              + {{ t("invoiceForm.addPosition") }}
            </UiButton>

            <UiButton type="button" data-test="generate-positions" @click="openPicker">
              {{ t("invoiceForm.generatePositions") }}
            </UiButton>

            <span class="ml-auto font-bold tabular-nums" data-test="total">
              {{ money.format(total) }}
            </span>
          </div>
        </template>
      </UiPanel>

      <UiFormActions
        :save-label="t('invoiceForm.save')"
        :cancel-label="t('invoiceForm.cancel')"
        :busy="busy"
        @cancel="router.push({ name: 'invoices' })"
      />
    </form>

    <!-- The picker the ERB opened as a Bootstrap modal. One task becomes one
         position, with the timers behind it carried along so the same time is
         never invoiced twice. -->
    <div v-if="pickerOpen" class="fixed inset-0 z-40 bg-ink/50" @click="pickerOpen = false"></div>
    <div v-if="pickerOpen" class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4">
      <div
        class="relative z-50 mt-10 w-full max-w-lg rounded-bs-lg border border-ink/20 bg-surface shadow-[0_5px_15px_rgba(0,0,0,0.5)]"
        data-test="position-picker"
      >
        <div class="flex items-center justify-between border-b border-rule px-4 py-3.5">
          <h3>{{ t("invoiceForm.pickerTitle") }}</h3>
          <button type="button" class="text-2xl leading-none opacity-20 hover:opacity-50" data-test="picker-close" @click="pickerOpen = false">
            ×
          </button>
        </div>

        <div class="px-4 py-3.5">
          <p v-if="loadingTimers" data-test="picker-loading">{{ t("invoiceForm.loading") }}</p>
          <p v-else-if="candidates.length === 0" data-test="picker-empty">
            {{ t("invoiceForm.nothingUninvoiced") }}
          </p>

          <label
            v-for="candidate in candidates"
            :key="candidate.taskId"
            class="flex items-center gap-2 py-1"
            :data-test="`candidate-${candidate.taskId}`"
          >
            <input v-model="picked" type="checkbox" :value="candidate.taskId" class="size-4 accent-brand" />
            <span class="grow">{{ candidate.name }}</span>
            <span class="tabular-nums text-muted">{{ candidate.hours }} h</span>
          </label>
        </div>

        <div class="flex justify-end gap-2 border-t border-rule px-4 py-3.5">
          <UiButton type="button" @click="pickerOpen = false">{{ t("invoiceForm.close") }}</UiButton>
          <UiButton
            type="button"
            variant="primary"
            :disabled="picked.length === 0"
            data-test="take-picked"
            @click="takePicked"
          >
            {{ t("invoiceForm.takePicked") }}
          </UiButton>
        </div>
      </div>
    </div>
  </div>
</template>

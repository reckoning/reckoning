<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useInvoice, useCreateInvoice, useUpdateInvoice } from "@/services/api/services/invoices/invoices"
import { useProjects, useProject } from "@/services/api/services/projects/projects"
import { useUninvoicedTimers } from "@/services/api/services/timers/timers"
import { useAccount } from "@/services/api/services/account/account"
import { useToastsStore } from "@/stores/toasts"

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
  // Which project the time behind this row was tracked against. The row fits
  // the invoice only while the invoice stays on that project — remembering it
  // rather than dropping the row makes switching away and back reversible.
  timerProjectId?: string
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

// `GET /projects` answers with the active ones. An invoice whose project has
// been archived since would open on a required select with no matching entry
// — unsavable, and silently wrong before it was required. Its own project
// therefore joins the list.
const projectOptions = computed(() => {
  const entries = (projects.value ?? []).map((entry) => ({
    id: entry.id,
    label: entry.label ?? entry.name,
  }))

  const own = invoice.value?.projectId

  if (own && !entries.some((entry) => entry.id === own)) {
    entries.unshift({id: own, label: invoice.value?.projectName ?? own})
  }

  return entries
})

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
      timerProjectId: loaded.projectId ?? undefined,
      // A saved rate is data, whoever typed it.
      rateFromProject: false,
      destroyed: false,
    }))
  },
  { immediate: true },
)

// Rows built from tracked time belong to the project they came from: the
// invoice takes its customer and its rate from the project, and the server
// refuses time from anywhere else. They leave the form with the project they
// belong to and come back with it — what the submitted request makes of them
// is decided in `positionsAttributes`, so nothing is destroyed on the way
// through an intermediate selection..
watch(projectId, () => {
  if (visibleRows.value.length === 0) rows.value.push(emptyRow())
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
    if (!row.rateFromProject) continue

    row.rate = rate
    // Nothing to derive a value from, so the stale one goes rather than
    // being billed. The marker stays: the rate still belongs to whichever
    // project is chosen, and the next one with a rate fills it in.
    if (rate === "") row.value = ""
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

// A row from another project's time is not shown: it is not part of this
// invoice while the invoice sits on this project.
function belongsToProject(row: Row): boolean {
  return row.timerProjectId === undefined || row.timerProjectId === projectId.value
}

const visibleRows = computed(() =>
  rows.value
    .map((row, index) => ({row, index}))
    .filter(({row}) => !row.destroyed && belongsToProject(row)),
)

// What the ERB did on every keystroke: hours imply a rate, and a rate with
// hours implies the value. A row with no hours keeps its value editable —
// that is a flat price.
function recalculate(row: Row): void {
  if (row.hours === "") return

  if (row.rate === "") {
    row.rate = String(projectRate.value ?? "")
    // Only a rate that was actually filled in sets the marker — a project
    // without one must not turn the row into a hand-typed rate.
    if (row.rate !== "") row.rateFromProject = true
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
      timerProjectId: projectId.value,
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
    // A saved row whose time belongs to another project is removed — the
    // server refuses that time on this invoice. An unsaved one simply never
    // goes along.
    .filter((row) => row.id || belongsToProject(row))
    .map((row) => {
      const foreign = !belongsToProject(row)

      return {
        ...(row.id ? {id: row.id} : {}),
        description: row.description,
        hours: row.hours === "" ? null : row.hours,
        rate: row.rate === "" ? null : row.rate,
        value: row.value === "" ? null : row.value,
        timer_ids: foreign ? [] : row.timerIds,
        ...(row.destroyed || foreign ? {_destroy: true} : {}),
      }
    })
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
  <div class="p-4">
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-[24px] font-medium" data-test="invoice-form-title">
        {{ editing ? t("invoiceForm.editTitle") : t("invoiceForm.newTitle") }}
      </h1>

      <RouterLink :to="{ name: 'invoices' }" class="text-sm underline" data-test="back">
        {{ t("invoiceForm.back") }}
      </RouterLink>
    </div>

    <p v-if="editing && isPending" data-test="loading">{{ t("invoiceForm.loading") }}</p>

    <p v-else-if="editing && isError" data-test="load-failed">{{ t("invoiceForm.loadFailed") }}</p>

    <p v-else-if="missingAddress" class="max-w-2xl border border-warning-border bg-warning p-3 text-sm text-white" data-test="missing-address">
      {{ t("invoiceForm.missingAddress") }}
      <a href="/settings#address" class="underline" data-test="account-settings">{{ t("invoiceForm.toSettings") }}</a>
    </p>

    <p v-else-if="limitReached" class="max-w-2xl border border-warning-border bg-warning p-3 text-sm text-white" data-test="limit-reached">
      {{ t("invoices.limitReached") }}
    </p>

    <form v-else class="flex flex-col gap-4" @submit.prevent="save">
      <div class="grid max-w-3xl gap-3 sm:grid-cols-2">
        <label class="text-sm">
          {{ t("invoiceForm.fields.project") }}
          <!-- `belongs_to :project` is required, so an invoice never has none.
               The empty entry is the "nothing picked yet" of a new invoice;
               on an existing one it would promise a clearing the server
               cannot carry out. -->
          <select v-model="projectId" required data-test="project" class="mt-1 block w-full rounded border border-field-border p-2">
            <option v-if="!editing" value="">{{ t("invoiceForm.fields.noProject") }}</option>
            <option v-for="entry in projectOptions" :key="entry.id" :value="entry.id">
              {{ entry.label }}
            </option>
          </select>
        </label>

        <label class="text-sm">
          {{ t("invoiceForm.fields.ref") }}
          <input v-model="ref_" type="number" data-test="ref" class="mt-1 block w-full rounded border border-field-border p-2" />
        </label>

        <label class="text-sm">
          {{ t("invoiceForm.fields.date") }}
          <input v-model="date" type="date" data-test="date" class="mt-1 block w-full rounded border border-field-border p-2" />
        </label>

        <label class="text-sm">
          {{ t("invoiceForm.fields.deliveryDate") }}
          <input v-model="deliveryDate" type="date" data-test="delivery-date" class="mt-1 block w-full rounded border border-field-border p-2" />
        </label>

        <label class="text-sm">
          {{ t("invoiceForm.fields.paymentDueDate") }}
          <input v-model="paymentDueDate" type="date" data-test="payment-due-date" class="mt-1 block w-full rounded border border-field-border p-2" />
        </label>
      </div>

      <fieldset class="border-t border-rule pt-3">
        <legend class="text-sm font-semibold">{{ t("invoiceForm.positions") }}</legend>

        <div class="flex flex-col gap-2" data-test="positions">
          <div v-for="{ row, index } in visibleRows" :key="row.id ?? `new-${index}`" class="flex flex-wrap items-center gap-2">
            <input
              v-model="row.description"
              type="text"
              :placeholder="t('invoiceForm.fields.description')"
              :data-test="`position-description-${index}`"
              class="min-w-60 grow rounded border border-field-border p-2 text-sm"
            />

            <input
              v-model="row.rate"
              type="number"
              step="0.01"
              :placeholder="t('invoiceForm.fields.rate')"
              :data-test="`position-rate-${index}`"
              class="w-24 rounded border border-field-border p-2 text-right text-sm tabular-nums"
              @input="rateTyped(row)"
            />

            <!-- Hours belong to the timers behind the row, so a generated one
                 shows them and does not offer them for editing. -->
            <input
              v-if="row.timerIds.length === 0"
              v-model="row.hours"
              type="number"
              step="0.01"
              :placeholder="t('invoiceForm.fields.hours')"
              :data-test="`position-hours-${index}`"
              class="w-24 rounded border border-field-border p-2 text-right text-sm tabular-nums"
              @input="recalculate(row)"
            />
            <span
              v-else
              class="w-24 p-2 text-right text-sm tabular-nums text-muted"
              :data-test="`position-hours-fixed-${index}`"
            >{{ row.hours }}</span>

            <input
              v-if="row.hours === ''"
              v-model="row.value"
              type="number"
              step="0.01"
              :placeholder="t('invoiceForm.fields.value')"
              :data-test="`position-value-${index}`"
              class="w-28 rounded border border-field-border p-2 text-right text-sm tabular-nums"
            />
            <span
              v-else
              class="w-28 p-2 text-right text-sm tabular-nums"
              :data-test="`position-value-computed-${index}`"
            >{{ row.value }}</span>

            <button type="button" class="text-sm text-danger underline" :data-test="`position-remove-${index}`" @click="removeRow(index)">
              {{ t("invoiceForm.removePosition") }}
            </button>
          </div>
        </div>

        <div class="mt-3 flex flex-wrap items-center gap-2">
          <button type="button" class="rounded border border-field-border px-3 py-1 text-sm" data-test="add-position" @click="addRow">
            {{ t("invoiceForm.addPosition") }}
          </button>

          <button type="button" class="rounded border border-field-border px-3 py-1 text-sm" data-test="generate-positions" @click="openPicker">
            {{ t("invoiceForm.generatePositions") }}
          </button>

          <span class="ml-auto text-sm font-semibold tabular-nums" data-test="total">
            {{ money.format(total) }}
          </span>
        </div>
      </fieldset>

      <button
        type="submit"
        class="self-start rounded-md border border-brand-border bg-brand px-4 py-2 text-white hover:bg-brand-hover disabled:opacity-60"
        :disabled="busy"
        data-test="submit"
      >
        {{ t("invoiceForm.save") }}
      </button>
    </form>

    <!-- The picker the ERB opened as a Bootstrap modal. One task becomes one
         position, with the timers behind it carried along so the same time is
         never invoiced twice. -->
    <div v-if="pickerOpen" class="fixed inset-0 z-40 bg-ink/40" @click="pickerOpen = false"></div>
    <div v-if="pickerOpen" class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4">
      <div class="relative z-50 w-full max-w-lg rounded border border-rule bg-surface shadow-lg" data-test="position-picker">
        <div class="flex items-center justify-between border-b border-rule px-4 py-3">
          <h2 class="text-base font-semibold">{{ t("invoiceForm.pickerTitle") }}</h2>
          <button type="button" class="text-sm underline" data-test="picker-close" @click="pickerOpen = false">
            {{ t("invoiceForm.close") }}
          </button>
        </div>

        <div class="px-4 py-3">
          <p v-if="loadingTimers" data-test="picker-loading">{{ t("invoiceForm.loading") }}</p>
          <p v-else-if="candidates.length === 0" data-test="picker-empty">{{ t("invoiceForm.nothingUninvoiced") }}</p>

          <label
            v-for="candidate in candidates"
            :key="candidate.taskId"
            class="flex items-center gap-2 py-1 text-sm"
            :data-test="`candidate-${candidate.taskId}`"
          >
            <input v-model="picked" type="checkbox" :value="candidate.taskId" class="h-[18px] w-[18px] rounded border border-control-border accent-brand" />
            <span class="grow">{{ candidate.name }}</span>
            <span class="tabular-nums text-muted">{{ candidate.hours }} h</span>
          </label>
        </div>

        <div class="flex justify-end gap-2 border-t border-rule px-4 py-3">
          <button
            type="button"
            class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover disabled:opacity-60"
            :disabled="picked.length === 0"
            data-test="take-picked"
            @click="takePicked"
          >
            {{ t("invoiceForm.takePicked") }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useOffer, useCreateOffer, useUpdateOffer } from "@/services/api/services/offers/offers"
import { useProjects, useProject } from "@/services/api/services/projects/projects"
import { useAccount } from "@/services/api/services/account/account"
import { useToastsStore } from "@/stores/toasts"

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()

const id = computed(() => (route.params.id ? String(route.params.id) : undefined))
const editing = computed(() => id.value !== undefined)

const { data: offer, isPending, isError } = useOffer(id.value ?? "", {
  query: { enabled: editing.value },
})
const { data: projects } = useProjects({}, { query: { enabled: !editing.value } })
const { data: account } = useAccount()
const { mutateAsync: create } = useCreateOffer()
const { mutateAsync: update } = useUpdateOffer()

interface Row {
  id?: string
  description: string
  rate: string
  hours: string
  value: string
  // Set when the project filled the rate in rather than the user. Comparing
  // the rate against the project's would mistake a hand-typed rate that
  // happens to match for one this form wrote.
  rateFromProject: boolean
  destroyed: boolean
}

const projectId = ref(String(route.query.project_id ?? ""))
const date = ref("")
const ref_ = ref("")
const description = ref("")
const rows = ref<Row[]>([])
const busy = ref(false)
const filledFrom = ref<string | undefined>()

const { data: project } = useProject(projectId, {
  query: { enabled: computed(() => projectId.value !== "") },
})

const projectRate = computed(() => project.value?.rate ?? "")

// The ERB `new` action refused to render without an account address — the
// offer's PDF carries it as the sender — and that guard lived in the action
// that just went away. The model refuses the create either way.
const missingAddress = computed(() => !editing.value && !(account.value?.address ?? "").trim())

function emptyRow(): Row {
  return {description: "", rate: "", hours: "", value: "", rateFromProject: false, destroyed: false}
}

watch(
  offer,
  (loaded) => {
    if (!loaded || filledFrom.value === loaded.id) return

    filledFrom.value = loaded.id
    projectId.value = loaded.projectId ?? ""
    date.value = (loaded.date ?? "").slice(0, 10)
    ref_.value = loaded.ref === null || loaded.ref === undefined ? "" : String(loaded.ref)
    description.value = loaded.description ?? ""
    rows.value = (loaded.positions ?? []).map((position) => ({
      id: position.id,
      description: position.description ?? "",
      rate: position.rate ?? "",
      hours: position.hours ?? "",
      value: position.value ?? "",
      // A saved rate is data, whoever typed it.
      rateFromProject: false,
      destroyed: false,
    }))
  },
  { immediate: true },
)

// A new offer starts with one empty row, the way `new` did.
watch(
  editing,
  (isEditing) => {
    if (!isEditing && rows.value.length === 0) rows.value = [emptyRow()]
  },
  { immediate: true },
)

// What the ERB tracked as `oldProjectRate`: a rate the project filled in
// follows the new project. A rate typed by hand stays put, which is why the
// rows carry the fact rather than being compared against the old rate.
watch(projectRate, (next) => {
  // The project query blanks out while the newly picked one loads, and that
  // gap is not a rate.
  const rate = String(next ?? "")
  if (rate === "") return

  for (const row of rows.value) {
    if (!row.rateFromProject) continue

    row.rate = rate
    recalculate(row)
  }
})

const visibleRows = computed(() =>
  rows.value.map((row, index) => ({row, index})).filter(({row}) => !row.destroyed),
)

// What the ERB did on every keystroke: hours imply the project's rate, and a
// rate with hours implies the value. A row with no hours keeps its value
// editable — that is a flat price.
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
      ...(row.destroyed ? {_destroy: true} : {}),
    }))
}

async function save(): Promise<void> {
  busy.value = true

  const data = {
    project_id: projectId.value || undefined,
    date: date.value || null,
    ref: ref_.value === "" ? null : Number(ref_.value),
    description: description.value || null,
    positions_attributes: positionsAttributes(),
  }

  try {
    const saved = editing.value
      ? await update({id: id.value as string, data})
      : await create({data})

    toasts.push("success", editing.value ? t("offerForm.saved") : t("offerForm.created"))
    await router.push({name: "offer", params: {id: saved.id}})
  } catch {
    toasts.push("error", t("offerForm.saveFailed"))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="p-4">
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-[24px] font-medium" data-test="offer-form-title">
        {{ editing ? t("offerForm.editTitle") : t("offerForm.newTitle") }}
      </h1>

      <RouterLink :to="{ name: 'offers' }" class="text-sm underline" data-test="back">
        {{ t("offerForm.back") }}
      </RouterLink>
    </div>

    <p v-if="editing && isPending" data-test="loading">{{ t("offerForm.loading") }}</p>

    <p v-else-if="editing && isError" data-test="load-failed">{{ t("offerForm.loadFailed") }}</p>

    <p v-else-if="missingAddress" class="max-w-2xl border border-warning-border bg-warning p-3 text-sm text-white" data-test="missing-address">
      {{ t("offerForm.missingAddress") }}
      <a href="/settings#address" class="underline" data-test="account-settings">{{ t("offerForm.toSettings") }}</a>
    </p>

    <form v-else class="flex flex-col gap-4" @submit.prevent="save">
      <div class="grid max-w-3xl gap-3 sm:grid-cols-2">
        <label v-if="!editing" class="text-sm">
          {{ t("offerForm.fields.project") }}
          <select v-model="projectId" data-test="project" class="mt-1 block w-full rounded border border-field-border p-2">
            <option value="">{{ t("offerForm.fields.noProject") }}</option>
            <option v-for="entry in projects ?? []" :key="entry.id" :value="entry.id">
              {{ entry.label ?? entry.name }}
            </option>
          </select>
        </label>

        <label class="text-sm">
          {{ t("offerForm.fields.ref") }}
          <input v-model="ref_" type="number" data-test="ref" class="mt-1 block w-full rounded border border-field-border p-2" />
        </label>

        <label class="text-sm">
          {{ t("offerForm.fields.date") }}
          <input v-model="date" type="date" data-test="date" class="mt-1 block w-full rounded border border-field-border p-2" />
        </label>
      </div>

      <label class="max-w-3xl text-sm">
        {{ t("offerForm.fields.description") }}
        <textarea
          v-model="description"
          rows="6"
          data-test="description"
          class="mt-1 block w-full rounded border border-field-border p-2"
        ></textarea>
      </label>

      <fieldset class="border-t border-rule pt-3">
        <legend class="text-sm font-semibold">{{ t("offerForm.positions") }}</legend>

        <div class="flex flex-col gap-2" data-test="positions">
          <div v-for="{ row, index } in visibleRows" :key="row.id ?? `new-${index}`" class="flex flex-wrap items-center gap-2">
            <input
              v-model="row.description"
              type="text"
              :placeholder="t('offerForm.fields.positionDescription')"
              :data-test="`position-description-${index}`"
              class="min-w-60 grow rounded border border-field-border p-2 text-sm"
            />

            <input
              v-model="row.rate"
              type="number"
              step="0.01"
              :placeholder="t('offerForm.fields.rate')"
              :data-test="`position-rate-${index}`"
              class="w-24 rounded border border-field-border p-2 text-right text-sm tabular-nums"
              @input="rateTyped(row)"
            />

            <input
              v-model="row.hours"
              type="number"
              step="0.01"
              :placeholder="t('offerForm.fields.hours')"
              :data-test="`position-hours-${index}`"
              class="w-24 rounded border border-field-border p-2 text-right text-sm tabular-nums"
              @input="recalculate(row)"
            />

            <input
              v-if="row.hours === ''"
              v-model="row.value"
              type="number"
              step="0.01"
              :placeholder="t('offerForm.fields.value')"
              :data-test="`position-value-${index}`"
              class="w-28 rounded border border-field-border p-2 text-right text-sm tabular-nums"
            />
            <span
              v-else
              class="w-28 p-2 text-right text-sm tabular-nums"
              :data-test="`position-value-computed-${index}`"
            >{{ row.value }}</span>

            <button type="button" class="text-sm text-danger underline" :data-test="`position-remove-${index}`" @click="removeRow(index)">
              {{ t("offerForm.removePosition") }}
            </button>
          </div>
        </div>

        <div class="mt-3 flex flex-wrap items-center gap-2">
          <button type="button" class="rounded border border-field-border px-3 py-1 text-sm" data-test="add-position" @click="addRow">
            {{ t("offerForm.addPosition") }}
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
        {{ t("offerForm.save") }}
      </button>
    </form>
  </div>
</template>

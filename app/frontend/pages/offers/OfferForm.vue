<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useOffer, useCreateOffer, useUpdateOffer } from "@/services/api/services/offers/offers"
import { useProjects, useProject } from "@/services/api/services/projects/projects"
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

const { data: offer, isPending, isError } = useOffer(id.value ?? "", {
  query: { enabled: editing.value },
})
const { data: projects } = useProjects()
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
  <div id="offer-form">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="offer-form-title">
        {{ editing ? t("offerForm.editTitle") : t("offerForm.newTitle") }}
      </h1>

      <div class="max-md:w-full">
        <RouterLink :to="{ name: 'offers' }" data-test="back">
          <UiButton class="max-md:w-full">{{ t("offerForm.back") }}</UiButton>
        </RouterLink>
      </div>
    </div>

    <p v-if="editing && isPending" class="mt-4" data-test="loading">{{ t("offerForm.loading") }}</p>

    <p v-else-if="editing && isError" class="mt-4" data-test="load-failed">
      {{ t("offerForm.loadFailed") }}
    </p>

    <UiAlert v-else-if="missingAddress" variant="warning" class="mt-4" data-test="missing-address">
      {{ t("offerForm.missingAddress") }}
      <a href="/settings#address" data-test="account-settings">{{ t("offerForm.toSettings") }}</a>
    </UiAlert>

    <form v-else class="mt-4" @submit.prevent="save">
      <div class="grid gap-4 md:grid-cols-2">
        <UiInput v-model="projectId" as="select" data-test="project">
          <option value="">{{ t("offerForm.fields.noProject") }}</option>
          <option v-for="entry in projects ?? []" :key="entry.id" :value="entry.id">
            {{ entry.label ?? entry.name }}
          </option>
        </UiInput>

        <UiInputGroup :addon="t('offerForm.fields.date')">
          <UiInput v-model="date" type="date" data-test="date" />
        </UiInputGroup>

        <UiInputGroup :addon="t('offerForm.fields.ref')">
          <UiInput v-model="ref_" type="number" data-test="ref" />
        </UiInputGroup>
      </div>

      <div class="mt-4 max-w-3xl">
        <label class="mb-1 inline-block font-bold">{{ t("offerForm.fields.description") }}</label>
        <UiInput v-model="description" as="textarea" rows="6" data-test="description" />
      </div>

      <UiPanel class="mt-5" :title="t('offerForm.positions')">
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
                  :placeholder="t('offerForm.fields.positionDescription')"
                  :data-test="`position-description-${index}`"
                />
              </div>

              <div class="col-span-4 md:col-span-2">
                <UiInputGroup :addon="t('offerForm.fields.rateAddon')">
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

              <div class="col-span-4 md:col-span-2">
                <UiInputGroup :addon="t('offerForm.fields.hoursAddon')">
                  <UiInput
                    v-model="row.hours"
                    type="number"
                    step="0.01"
                    class="text-right"
                    :data-test="`position-hours-${index}`"
                    @input="recalculate(row)"
                  />
                </UiInputGroup>
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
              + {{ t("offerForm.addPosition") }}
            </UiButton>

            <span class="ml-auto font-bold tabular-nums" data-test="total">
              {{ money.format(total) }}
            </span>
          </div>
        </template>
      </UiPanel>

      <UiFormActions
        :save-label="t('offerForm.save')"
        :cancel-label="t('offerForm.cancel')"
        :busy="busy"
        @cancel="router.push({ name: 'offers' })"
      />
    </form>
  </div>
</template>

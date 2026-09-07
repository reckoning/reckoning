<script setup lang="ts">
import { computed, ref } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useQueryClient } from "@tanstack/vue-query"
import {
  useOffer,
  useTransitionOffer,
  useDestroyOffer,
  getOfferQueryKey,
} from "@/services/api/services/offers/offers"
import type { OfferAbilitiesTransitionsItem } from "@/services/api/models/OfferAbilitiesTransitionsItem"
import PdfViewer from "@/components/PdfViewer.vue"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const toasts = useToastsStore()
const queryClient = useQueryClient()

const id = String(route.params.id)

const { data: offer, isPending, isError } = useOffer(id)
const { mutateAsync: transition } = useTransitionOffer()
const { mutateAsync: destroy } = useDestroyOffer()

const busy = ref(false)

// What this user may do, as the endpoint reports it — the state machine's own
// answer plus the user's abilities. An expired trial reads everything and
// writes nothing, and `editable` is a property of the record rather than a
// permission: it says a bided offer cannot be edited while the ability says
// it can.
const abilities = computed(() => offer.value?.abilities)

// The filename segment is decorative: `send_data` sets the download name from
// the record, and the preview is fetched by pdf.js either way.
const offerPdf = computed(() => `/offers/${id}/pdf/offer.pdf`)

const money = computed(
  () => new Intl.NumberFormat(locale.value, {style: "currency", currency: "EUR"}),
)
const dates = computed(
  () => new Intl.DateTimeFormat(locale.value, {dateStyle: "medium", timeZone: "UTC"}),
)

function formatDate(value: string | null | undefined): string {
  return value ? dates.value.format(new Date(`${value.slice(0, 10)}T00:00:00Z`)) : ""
}

async function moveAlong(event: OfferAbilitiesTransitionsItem): Promise<void> {
  const confirmed = await confirmDialog(t(`offer.confirm.${event}`))
  if (!confirmed) return

  busy.value = true

  try {
    await transition({id, event})
    toasts.push("success", t(`offer.done.${event}`))
    await queryClient.invalidateQueries({queryKey: getOfferQueryKey(id)})
  } catch {
    toasts.push("error", t("offer.actionFailed"))
  } finally {
    busy.value = false
  }
}

async function removeOffer(): Promise<void> {
  if (!(await confirmDialog(t("offer.confirmDelete")))) return

  try {
    await destroy({id})
    toasts.push("success", t("offer.deleted"))
    await router.push({name: "offers"})
  } catch {
    toasts.push("error", t("offer.deleteFailed"))
  }
}
</script>

<template>
  <div class="p-4">
    <p v-if="isPending" data-test="loading">{{ t("offer.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("offer.loadFailed") }}</p>

    <div v-else-if="offer">
      <div class="mb-4 flex flex-wrap items-center gap-3">
        <h1 class="text-[24px] font-medium" data-test="offer-title">
          {{ t("offer.title", { ref: offer.refNumber ?? offer.ref }) }}
        </h1>

        <span class="rounded border border-rule px-2 py-1 text-[13px] text-muted" data-test="state">
          {{ t(`offers.states.${offer.state}`) }}
        </span>

        <div class="ml-auto flex flex-wrap gap-2">
          <button
            v-for="event in abilities?.transitions ?? []"
            :key="event"
            type="button"
            class="rounded-md border border-brand-border bg-brand px-4 py-2 text-sm text-white hover:bg-brand-hover disabled:opacity-60"
            :disabled="busy"
            :data-test="`transition-${event}`"
            @click="moveAlong(event)"
          >
            {{ t(`offer.transitions.${event}`) }}
          </button>

          <RouterLink :to="{ name: 'offers' }" class="rounded border border-field-border px-4 py-2 text-sm" data-test="back">
            {{ t("offer.back") }}
          </RouterLink>
        </div>
      </div>

      <dl class="mb-4 grid grid-cols-2 gap-2 text-sm sm:grid-cols-4" data-test="facts">
        <div>
          <dt class="text-muted">{{ t("offer.fields.customer") }}</dt>
          <dd>{{ offer.customerName }}</dd>
        </div>
        <div>
          <dt class="text-muted">{{ t("offer.fields.project") }}</dt>
          <dd>{{ offer.projectName }}</dd>
        </div>
        <div>
          <dt class="text-muted">{{ t("offer.fields.date") }}</dt>
          <dd class="tabular-nums">{{ formatDate(offer.date) }}</dd>
        </div>
        <div>
          <dt class="text-muted">{{ t("offer.fields.value") }}</dt>
          <dd class="tabular-nums" data-test="value">{{ money.format(Number(offer.value ?? 0)) }}</dd>
        </div>
      </dl>

      <div class="mb-6 flex flex-wrap gap-3 text-sm">
        <a :href="offerPdf" target="_blank" class="text-brand underline" data-test="offer-pdf">
          {{ t("offer.download") }}
        </a>
        <RouterLink
          v-if="abilities?.update"
          :to="{ name: 'offer-edit', params: { id } }"
          class="text-brand underline"
          data-test="edit"
        >
          {{ t("offer.edit") }}
        </RouterLink>
        <button
          v-if="abilities?.destroy"
          type="button"
          class="text-danger underline"
          data-test="delete"
          @click="removeOffer"
        >
          {{ t("offer.delete") }}
        </button>
      </div>

      <p v-if="offer.description" class="mb-6 max-w-3xl whitespace-pre-line text-sm" data-test="description">
        {{ offer.description }}
      </p>

      <table class="mb-6 w-full border-collapse text-sm" data-test="positions">
        <thead>
          <tr class="border-b border-rule-strong text-left">
            <th class="px-2 py-2">{{ t("offer.positions.description") }}</th>
            <th class="px-2 py-2 text-right">{{ t("offer.positions.hours") }}</th>
            <th class="px-2 py-2 text-right">{{ t("offer.positions.rate") }}</th>
            <th class="px-2 py-2 text-right">{{ t("offer.positions.value") }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="position in offer.positions ?? []" :key="position.id" class="border-b border-rule">
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

      <section>
        <h2 class="mb-2 text-base font-semibold">{{ t("offer.preview") }}</h2>
        <PdfViewer :src="offerPdf" data-test="offer-preview" />
      </section>
    </div>
  </div>
</template>

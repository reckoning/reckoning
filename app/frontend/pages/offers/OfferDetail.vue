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
import UiButton from "@/components/ui/UiButton.vue"
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

const { data: offer, isPending, isError } = useOffer(id)
const { mutateAsync: transition } = useTransitionOffer()
const { mutateAsync: destroy } = useDestroyOffer()

const busy = ref(false)

// The preview was a tab strip with a single tab; kept so the screen reads the
// same as the invoice beside it.
const tabs = computed(() => [{key: "offer", label: t("offer.preview")}])

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
  <div id="offer">
    <p v-if="isPending" data-test="loading">{{ t("offer.loading") }}</p>
    <p v-else-if="isError" data-test="error">{{ t("offer.loadFailed") }}</p>

    <template v-else-if="offer">
      <div class="flex flex-wrap items-start gap-4">
        <h1 class="grow" data-test="offer-title">
          {{ t("offer.title", { ref: offer.refNumber ?? offer.ref }) }}
          <small class="ml-1">
            <UiLabel :variant="offer.state === 'created' ? 'default' : 'primary'" data-test="state">
              {{ t(`offers.states.${offer.state}`) }}
            </UiLabel>
          </small>
        </h1>

        <div class="flex flex-wrap gap-2 max-md:w-full max-md:flex-col">
          <UiButton
            v-for="event in abilities?.transitions ?? []"
            :key="event"
            variant="primary"
            :disabled="busy"
            :data-test="`transition-${event}`"
            @click="moveAlong(event)"
          >
            {{ t(`offer.transitions.${event}`) }}
          </UiButton>

          <RouterLink :to="{ name: 'offers' }" data-test="back">
            <UiButton as="span" class="max-md:w-full">{{ t("offer.back") }}</UiButton>
          </RouterLink>
        </div>
      </div>

      <div class="mt-4 grid gap-4 md:grid-cols-3">
        <div class="md:col-span-2">
          <UiNavTabs :tabs="tabs" active="offer" />

          <PdfViewer :src="offerPdf" data-test="offer-preview" />
        </div>

        <div class="md:pt-10">
          <UiPanel :title="t('offer.downloads')">
            <UiListGroup>
              <UiListGroupItem :href="offerPdf" target="_blank" data-test="offer-pdf">
                <i class="fa fa-download"></i>
                {{ t("offer.download") }}
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>

          <UiPanel :title="t('offer.actions')">
            <UiListGroup>
              <UiListGroupItem
                v-if="abilities?.update"
                :to="{ name: 'offer-edit', params: { id } }"
                data-test="edit"
              >
                <i class="fa fa-edit"></i>
                {{ t("offer.edit") }}
              </UiListGroupItem>

              <UiListGroupItem
                v-if="abilities?.destroy"
                action
                data-test="delete"
                @click="removeOffer"
              >
                <i class="fa fa-trash"></i>
                {{ t("offer.delete") }}
              </UiListGroupItem>
            </UiListGroup>
          </UiPanel>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue"
import { useRoute, useRouter } from "vue-router"
import { useI18n } from "vue-i18n"
import { useAccount, useUpdateAccount } from "@/services/api/services/account/account"
import { useToastsStore } from "@/stores/toasts"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormGroup from "@/components/ui/UiFormGroup.vue"
import UiInput from "@/components/ui/UiInput.vue"
import UiInputGroup from "@/components/ui/UiInputGroup.vue"

// The sections `accounts/_nav` lists, in its order and with its icons. Each
// is a form of its own that saves only what it shows, the way the six
// partials each carried their own submit.
const SECTIONS = [
  { key: "basic", icon: "fa-book" },
  { key: "address", icon: "fa-globe" },
  { key: "banking", icon: "fa-bank" },
  { key: "taxes", icon: "fa-building" },
  { key: "mailing", icon: "fa-send" },
  { key: "offer", icon: "fa-hand-holding-box" },
] as const

type Section = (typeof SECTIONS)[number]["key"]

const FIELDS: Record<Section, readonly string[]> = {
  basic: ["name", "subdomain"],
  address: [
    "address",
    "country",
    "telefon",
    "fax",
    "publicEmail",
    "website",
    "officeSpace",
    "deductibleOfficeSpace",
  ],
  banking: ["bank", "iban", "bic"],
  taxes: ["tax", "provision", "vatId"],
  mailing: ["signature"],
  offer: ["offerHeadline"],
}

const NUMBERS = ["officeSpace", "deductibleOfficeSpace"] as const

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const { data: account, isPending } = useAccount()
const { mutateAsync: update } = useUpdateAccount()

// The section is the hash, the way it was on the server-rendered screen: a
// link into one of them keeps working, and so does the back button.
const active = computed<Section>(() => {
  const hash = route.hash.replace("#", "")

  return SECTIONS.some((section) => section.key === hash) ? (hash as Section) : "basic"
})

function open(section: Section): void {
  router.push({ hash: `#${section}` })
}

// One bag of values for the whole account, because that is what the endpoint
// takes; each form sends the fields it shows out of it.
const values = reactive<Record<string, string>>({})

// Only the first answer fills the fields: vue-query refetches, and doing it
// again would throw away what is being typed.
const filled = ref(false)

watch(
  account,
  (loaded) => {
    if (!loaded || filled.value) return

    filled.value = true

    for (const field of Object.values(FIELDS).flat()) {
      const raw = (loaded as unknown as Record<string, unknown>)[field]
      values[field] = raw === null || raw === undefined ? "" : String(raw)
    }
  },
  { immediate: true },
)

const busy = ref(false)

// The domain the subdomain sits under, which the form printed after the
// field as an addon.
const domain = computed(() => window.location.host.replace(/^[^.]+\./, ""))

async function save(section: Section): Promise<void> {
  busy.value = true

  const data: Record<string, string | number | null> = {}

  for (const field of FIELDS[section]) {
    const entered = values[field] ?? ""

    // The two space fields are integers, and blank means "not entered"
    // rather than zero — a zero would claim an office of no size.
    data[field] = NUMBERS.some((number) => number === field)
      ? entered === ""
        ? null
        : Number(entered)
      : entered
  }

  try {
    await update({ data })
    toasts.push("success", t("accountSettings.saved"))
  } catch {
    toasts.push("error", t("accountSettings.saveFailed"))
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div id="account">
    <h1>{{ t("accountSettings.title") }}</h1>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("accountSettings.loading") }}</p>

    <div v-else class="mt-4 flex flex-wrap gap-6 md:flex-nowrap">
      <div class="w-full md:w-3/4">
        <fieldset v-if="active === 'basic'" data-test="section-basic">
          <legend class="bs-legend">{{ t("accountSettings.sections.basic") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('basic')">
            <UiFormGroup :label="t('accountSettings.fields.name')">
              <UiInput v-model="values.name" data-test="name" />
            </UiFormGroup>

            <UiFormGroup :label="t('accountSettings.fields.subdomain')">
              <UiInputGroup :addon-after="`.${domain}`">
                <UiInput v-model="values.subdomain" data-test="subdomain" />
              </UiInputGroup>
            </UiFormGroup>

            <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit-basic">
              {{ t("accountSettings.save") }}
            </UiButton>
          </form>
        </fieldset>

        <fieldset v-else-if="active === 'address'" data-test="section-address">
          <legend class="bs-legend">{{ t("accountSettings.sections.address") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('address')">
            <div class="flex flex-wrap gap-x-4">
              <UiFormGroup class="grow" :label="t('accountSettings.fields.address')">
                <UiInput v-model="values.address" as="textarea" rows="2" data-test="address" />
              </UiFormGroup>

              <UiFormGroup class="grow" :label="t('accountSettings.fields.country')">
                <UiInput v-model="values.country" data-test="country" />
              </UiFormGroup>
            </div>

            <div class="flex flex-wrap gap-x-4">
              <UiFormGroup class="grow" :label="t('accountSettings.fields.telefon')">
                <UiInput v-model="values.telefon" data-test="telefon" />
              </UiFormGroup>

              <UiFormGroup class="grow" :label="t('accountSettings.fields.fax')">
                <UiInput v-model="values.fax" data-test="fax" />
              </UiFormGroup>
            </div>

            <div class="flex flex-wrap gap-x-4">
              <UiFormGroup class="grow" :label="t('accountSettings.fields.publicEmail')">
                <UiInput v-model="values.publicEmail" type="email" data-test="public-email" />
              </UiFormGroup>

              <UiFormGroup class="grow" :label="t('accountSettings.fields.website')">
                <UiInput v-model="values.website" data-test="website" />
              </UiFormGroup>
            </div>

            <!-- What the account may deduct for its office is worked out from
                 these two, and an expense of that kind deducts nothing until
                 both are here. -->
            <div class="flex flex-wrap gap-x-4">
              <UiFormGroup class="grow" :label="t('accountSettings.fields.officeSpace')">
                <UiInputGroup addon-after="m²">
                  <UiInput
                    v-model="values.officeSpace"
                    type="number"
                    min="0"
                    class="text-right"
                    data-test="office-space"
                  />
                </UiInputGroup>
              </UiFormGroup>

              <UiFormGroup class="grow" :label="t('accountSettings.fields.deductibleOfficeSpace')">
                <UiInputGroup addon-after="m²">
                  <UiInput
                    v-model="values.deductibleOfficeSpace"
                    type="number"
                    min="0"
                    class="text-right"
                    data-test="deductible-office-space"
                  />
                </UiInputGroup>
              </UiFormGroup>
            </div>

            <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit-address">
              {{ t("accountSettings.save") }}
            </UiButton>
          </form>
        </fieldset>

        <fieldset v-else-if="active === 'banking'" data-test="section-banking">
          <legend class="bs-legend">{{ t("accountSettings.sections.banking") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('banking')">
            <UiFormGroup :label="t('accountSettings.fields.bank')">
              <UiInput v-model="values.bank" data-test="bank" />
            </UiFormGroup>

            <div class="flex flex-wrap gap-x-4">
              <UiFormGroup class="grow" :label="t('accountSettings.fields.iban')">
                <UiInput v-model="values.iban" data-test="iban" />
              </UiFormGroup>

              <UiFormGroup class="grow" :label="t('accountSettings.fields.bic')">
                <UiInput v-model="values.bic" data-test="bic" />
              </UiFormGroup>
            </div>

            <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit-banking">
              {{ t("accountSettings.save") }}
            </UiButton>
          </form>
        </fieldset>

        <fieldset v-else-if="active === 'taxes'" data-test="section-taxes">
          <legend class="bs-legend">{{ t("accountSettings.sections.taxes") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('taxes')">
            <UiFormGroup :label="t('accountSettings.fields.vatId')">
              <UiInput v-model="values.vatId" data-test="vat-id" />
            </UiFormGroup>

            <div class="flex flex-wrap gap-x-4">
              <UiFormGroup class="grow" :label="t('accountSettings.fields.tax')">
                <UiInputGroup addon-after="%">
                  <UiInput v-model="values.tax" class="text-right" data-test="tax" />
                </UiInputGroup>
              </UiFormGroup>

              <!-- The share put aside for tax, which the dashboard reports
                   as the provision. -->
              <UiFormGroup class="grow" :label="t('accountSettings.fields.provision')">
                <UiInputGroup addon-after="%">
                  <UiInput v-model="values.provision" class="text-right" data-test="provision" />
                </UiInputGroup>
              </UiFormGroup>
            </div>

            <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit-taxes">
              {{ t("accountSettings.save") }}
            </UiButton>
          </form>
        </fieldset>

        <fieldset v-else-if="active === 'mailing'" data-test="section-mailing">
          <legend class="bs-legend">{{ t("accountSettings.sections.mailing") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('mailing')">
            <UiFormGroup :label="t('accountSettings.fields.signature')">
              <UiInput v-model="values.signature" as="textarea" rows="6" data-test="signature" />
            </UiFormGroup>

            <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit-mailing">
              {{ t("accountSettings.save") }}
            </UiButton>
          </form>
        </fieldset>

        <fieldset v-else data-test="section-offer">
          <legend class="bs-legend">{{ t("accountSettings.sections.offer") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('offer')">
            <UiFormGroup :label="t('accountSettings.fields.offerHeadline')">
              <UiInput
                v-model="values.offerHeadline"
                as="textarea"
                rows="6"
                data-test="offer-headline"
              />
            </UiFormGroup>

            <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit-offer">
              {{ t("accountSettings.save") }}
            </UiButton>
          </form>
        </fieldset>
      </div>

      <!-- The sections down the side, the way `accounts/_nav` had them. -->
      <ul class="bs-nav-tabs-vertical w-full list-none md:w-1/4" data-test="sections">
        <li v-for="section in SECTIONS" :key="section.key">
          <a
            :href="`#${section.key}`"
            :class="active === section.key ? 'is-active' : ''"
            :data-test="`section-link-${section.key}`"
            @click.prevent="open(section.key)"
          >
            <i class="fa fa-fw" :class="section.icon"></i>
            {{ t(`accountSettings.nav.${section.key}`) }}
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

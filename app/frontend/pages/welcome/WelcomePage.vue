<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue"
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { usePlans } from "@/services/api/services/plans/plans"
import { useAppConfig } from "@/composables/useAppConfig"
import example1 from "@/images/example-1.png"
import example1Small from "@/images/example-1-small.png"
import example2 from "@/images/example-2.png"
import example2Small from "@/images/example-2-small.png"
import example3 from "@/images/example-3.png"
import example3Small from "@/images/example-3-small.png"
import github from "@/images/github.png"

const { t, tm, locale } = useI18n()
const { config } = useAppConfig()

const registrationEnabled = computed(() => config.value?.registrationEnabled === true)

// Everything below the screenshots is an offer, so it only exists where
// signing up does — `welcome.html.erb` wrapped it in the same condition.
const { data: plans, isError: plansFailed } = usePlans({
  query: { enabled: registrationEnabled },
})

const SHOTS = [
  { full: example1, small: example1Small, caption: "welcome.shots.invoices" },
  { full: example2, small: example2Small, caption: "welcome.shots.states" },
  { full: example3, small: example3Small, caption: "welcome.shots.records" },
] as const

const FEATURES = ["invoices", "timesheet", "projects"] as const

// `tm` returns the raw message, which for these is the list of lines under
// the heading.
function featureLines(key: string): string[] {
  return tm(`welcome.features.${key}.lines`) as unknown as string[]
}

const zoomed = ref<{ src: string; caption: string } | null>(null)

function onKeydown(event: KeyboardEvent): void {
  if (event.key === "Escape") zoomed.value = null
}

onMounted(() => document.addEventListener("keydown", onKeydown))
onBeforeUnmount(() => document.removeEventListener("keydown", onKeydown))

const number = computed(
  () => new Intl.NumberFormat(locale.value, { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
)

function price(cents: number): string {
  return number.value.format(cents / 100)
}

// `plans.small_print` prices each extra user at what the base plan costs, and
// `Plan.base` is the one called `basic` — not whichever sorts first, which a
// discount on another plan can change.
const basePrice = computed(() => {
  const base = plans.value?.find((plan) => plan.code === "basic")

  return base ? price(base.price) : null
})
</script>

<template>
  <div class="relative">
    <a
      href="https://github.com/reckoning/app"
      class="absolute top-0 right-0 hidden md:block"
      data-test="github-link"
    >
      <img :src="github" :alt="t('welcome.github')" class="border-0" />
    </a>

    <div class="bs-page-header">
      <h1>
        {{ t("welcome.headline") }}
        <br />
        <small>{{ t("welcome.subline") }}</small>
      </h1>
    </div>

    <div class="grid gap-[30px] md:grid-cols-3">
      <div v-for="shot in SHOTS" :key="shot.caption">
        <button
          type="button"
          class="bs-thumbnail w-full"
          data-test="screenshot"
          @click="zoomed = { src: shot.full, caption: t(shot.caption) }"
        >
          <img :src="shot.small" :alt="t(shot.caption)" class="w-full" />
        </button>
        <h4 class="mt-2 mb-2.5 text-center text-[length:var(--text-h3)] font-medium">
          {{ t(shot.caption) }}
        </h4>
      </div>
    </div>

    <template v-if="registrationEnabled">
      <hr class="my-5 border-t border-rule" />

      <h2>{{ t("welcome.featuresTitle") }}</h2>

      <div class="grid gap-[30px] md:grid-cols-3">
        <div v-for="feature in FEATURES" :key="feature">
          <ul class="list-disc pl-5">
            <li>
              {{ t(`welcome.features.${feature}.title`) }}
              <ul class="list-disc pl-5">
                <li v-for="line in featureLines(feature)" :key="line">{{ line }}</li>
              </ul>
            </li>
          </ul>
        </div>
      </div>

      <template v-if="plansFailed || plans?.length">
        <hr class="my-5 border-t border-rule" />

        <!-- A page that quietly drops its prices reads like an app with
             nothing to sell. The offer stands either way; only the table is
             missing. -->
        <p v-if="plansFailed" class="text-center text-muted" data-test="plans-failed">
          {{ t("welcome.plansFailed") }}
        </p>

        <!-- However many plans there are, they sit in the middle of the page
             — the server-rendered table was a fixed three-column row. -->
        <div
          v-if="plans?.length"
          class="mx-auto flex max-w-[980px] flex-wrap justify-center gap-[30px]"
          data-test="plans"
        >
          <div
            v-for="plan in plans"
            :key="plan.id"
            class="bs-panel mt-2.5 w-full max-w-[280px]"
            :class="plan.featured ? 'scale-110' : ''"
            data-test="plan"
          >
            <div class="bs-panel-heading bg-surface-muted">
              <h3 class="mt-1 mb-0 text-center font-brand text-[160%]">{{ plan.name }}</h3>
            </div>

            <ul class="[&>*+*]:border-t [&>*+*]:border-rule-strong">
              <!-- The lines are authored in the locale with the number in
                   bold, the way the pricing table has always printed them. -->
              <li
                v-for="(description, index) in plan.descriptions"
                :key="index"
                class="bs-list-item text-center"
                v-html="description"
              ></li>
            </ul>

            <div class="bs-panel-footer pt-5">
              <h2 class="text-center">
                <sup>€</sup> {{ price(plan.price) }}
                <small>{{ t(`welcome.per.${plan.interval}`) }}</small>
              </h2>
            </div>
          </div>
        </div>

        <div class="mx-auto max-w-[980px]">
          <p v-if="basePrice" class="text-right text-muted" data-test="small-print">
            {{ t("welcome.smallPrint", { price: basePrice }) }}
          </p>

          <div class="text-center">
            <RouterLink
              :to="{ name: 'signup' }"
              data-test="sign-up"
              class="inline-block rounded-bs-lg border border-success-border bg-success px-[16px] py-[10px] text-[18px] text-white hover:bg-success-hover hover:no-underline"
            >
              {{ t("welcome.cta") }}
            </RouterLink>
          </div>
        </div>
      </template>
    </template>

    <div
      v-if="zoomed"
      class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-ink/50 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="screenshot-modal-title"
      data-test="screenshot-modal"
      @click.self="zoomed = null"
    >
      <div class="bs-modal relative mt-10 w-full max-w-[80%]">
        <div class="flex items-center justify-between border-b border-rule px-4 py-3.5">
          <h4 id="screenshot-modal-title">{{ zoomed.caption }}</h4>
          <button
            type="button"
            class="text-2xl leading-none opacity-20 hover:opacity-50"
            :aria-label="t('welcome.close')"
            data-test="close-screenshot"
            @click="zoomed = null"
          >
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="p-4">
          <img :src="zoomed.src" :alt="zoomed.caption" class="w-full" />
        </div>
      </div>
    </div>
  </div>
</template>

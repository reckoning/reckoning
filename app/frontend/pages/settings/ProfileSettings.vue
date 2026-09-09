<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import { useMe, useUpdateMe } from "@/services/api/services/me/me"
import { useCurrentUserStore } from "@/stores/currentUser"
import { useToastsStore } from "@/stores/toasts"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormGroup from "@/components/ui/UiFormGroup.vue"
import UiInput from "@/components/ui/UiInput.vue"

// The two sections `users/_nav` lists, with its icons. Each saves what it
// shows, the way the one form behind both tabs did in one go.
const SECTIONS = [
  { key: "basic", icon: "fa-user" },
  { key: "security", icon: "fa-laptop" },
] as const

type Section = (typeof SECTIONS)[number]["key"]

const FIELDS: Record<Section, readonly string[]> = {
  basic: ["name"],
  security: ["email", "gravatar"],
}

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()
const currentUser = useCurrentUserStore()

const { data: user, isPending, isError } = useMe()
const { mutateAsync: update } = useUpdateMe()

const active = computed<Section>(() => {
  const hash = route.hash.replace("#", "")

  return SECTIONS.some((section) => section.key === hash) ? (hash as Section) : "basic"
})

function open(section: Section): void {
  router.push({ hash: `#${section}` })
}

const values = reactive<Record<string, string>>({})
const filled = ref(false)

watch(
  user,
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

async function save(section: Section): Promise<void> {
  busy.value = true

  const data: Record<string, string> = {}
  for (const field of FIELDS[section]) data[field] = values[field] ?? ""

  try {
    await update({ data })
    // The shell reads the email and the avatar from the store, and both are
    // editable right here — without this it keeps showing who you were
    // until the next full load.
    await currentUser.refresh()
    toasts.push("success", t("profileSettings.saved"))
  } catch {
    toasts.push("error", t("profileSettings.saveFailed"))
  } finally {
    busy.value = false
  }
}

// Two-factor is either on or it is not, and the badge beside the button
// said which — green with a tick, red with a cross.
const twoFactorOn = computed(() => user.value?.otpRequired === true)
</script>

<template>
  <div id="profile">
    <h1>{{ t("profileSettings.title") }}</h1>

    <p v-if="isPending" class="mt-4" data-test="loading">{{ t("profileSettings.loading") }}</p>

    <!-- No fields until the profile is here: they would render empty, and
         saving a section would write those blanks over what is stored. -->
    <UiAlert v-else-if="isError || !user" variant="danger" class="mt-4" data-test="load-failed">
      {{ t("profileSettings.loadFailed") }}
    </UiAlert>

    <div v-else class="mt-4 flex flex-wrap gap-6 md:flex-nowrap">
      <div class="w-full md:w-3/4">
        <fieldset v-if="active === 'basic'" data-test="section-basic">
          <legend class="bs-legend">{{ t("profileSettings.sections.basic") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('basic')">
            <UiFormGroup :label="t('profileSettings.fields.name')">
              <UiInput v-model="values.name" data-test="name" />
            </UiFormGroup>

            <UiButton
              variant="primary"
              size="large"
              type="submit"
              :disabled="busy"
              data-test="submit-basic"
            >
              {{ t("profileSettings.save") }}
            </UiButton>
          </form>
        </fieldset>

        <fieldset v-else data-test="section-security">
          <legend class="bs-legend">{{ t("profileSettings.sections.security") }}</legend>

          <form class="max-w-2xl" @submit.prevent="save('security')">
            <UiFormGroup :label="t('profileSettings.fields.email')">
              <UiInput v-model="values.email" type="email" data-test="email" />
            </UiFormGroup>

            <!-- The address the avatar is looked up under, which is not
                 necessarily the one you sign in with. -->
            <UiFormGroup :label="t('profileSettings.fields.gravatar')">
              <UiInput v-model="values.gravatar" type="email" data-test="gravatar" />
            </UiFormGroup>

            <UiButton
              variant="primary"
              size="large"
              type="submit"
              :disabled="busy"
              data-test="submit-security"
            >
              {{ t("profileSettings.save") }}
            </UiButton>
          </form>

          <hr class="my-5 border-t border-rule" />

          <div class="flex flex-wrap items-start gap-4">
            <div class="bs-btn-group">
              <RouterLink :to="{ name: 'two-factor' }" data-test="two-factor">
                <UiButton as="span">
                  <i class="fa fa-qrcode"></i>
                  {{ t("profileSettings.twoFactor") }}
                </UiButton>
              </RouterLink>
              <!-- Not a control: it says what the state is, the way the
                   disabled button beside the link did. -->
              <UiButton
                as="span"
                :variant="twoFactorOn ? 'success' : 'danger'"
                :title="twoFactorOn ? t('profileSettings.twoFactorOn') : t('profileSettings.twoFactorOff')"
                data-test="two-factor-state"
              >
                <i class="fa" :class="twoFactorOn ? 'fa-check' : 'fa-close'"></i>
              </UiButton>
            </div>

            <RouterLink :to="{ name: 'password-change' }" data-test="change-password">
              <UiButton as="span" variant="warning">
                {{ t("profileSettings.changePassword") }}
              </UiButton>
            </RouterLink>
          </div>
        </fieldset>
      </div>

      <ul class="bs-nav-tabs-vertical w-full list-none md:w-1/4" data-test="sections">
        <li v-for="section in SECTIONS" :key="section.key">
          <a
            :href="`#${section.key}`"
            :class="active === section.key ? 'is-active' : ''"
            :data-test="`section-link-${section.key}`"
            @click.prevent="open(section.key)"
          >
            <i class="fa fa-fw" :class="section.icon"></i>
            {{ t(`profileSettings.nav.${section.key}`) }}
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

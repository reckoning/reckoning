<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import {
  useBackendAccount,
  useCreateBackendAccount,
  useUpdateBackendAccount,
  useDestroyBackendAccount,
} from "@/services/api/services/backend/backend"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiFormGroup from "@/components/ui/UiFormGroup.vue"
import UiInput from "@/components/ui/UiInput.vue"

// `backend/accounts/{new,edit}`. Creating takes the first user's address with
// it, because an account is invalid without a user; editing leaves the users
// to their own screen and offers the name and the two feature flags, which is
// what the server-rendered form had. The plan is shown on the list and not
// editable here: the endpoint takes it, but no screen ever offered it, and
// the codes are `Plan` records rather than a fixed set to put in a select.
const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const id = computed(() => (route.params.id ? String(route.params.id) : undefined))
const editing = computed(() => id.value !== undefined)

const { data: account, isPending, isError } = useBackendAccount(
  computed(() => id.value ?? ""),
  { query: { enabled: computed(() => editing.value) } },
)
const { mutateAsync: create } = useCreateBackendAccount()
const { mutateAsync: update } = useUpdateBackendAccount()
const { mutateAsync: destroy } = useDestroyBackendAccount()

const name = ref("")
const email = ref("")
const featureExpenses = ref(false)
const featureLogbook = ref(false)
const errors = ref<string[]>([])
const saving = ref(false)

watch(
  account,
  (current) => {
    if (!current) return

    name.value = current.name
    featureExpenses.value = current.featureExpenses
    featureLogbook.value = current.featureLogbook
  },
  { immediate: true },
)

const loading = computed(() => editing.value && isPending.value)
const failed = computed(() => editing.value && isError.value)

function refuse(error: unknown): void {
  const data = (error as {response?: {data?: {errors?: Record<string, string[]>; message?: string}}})
    .response?.data
  const messages = Object.entries(data?.errors ?? {}).map(
    ([field, list]) => `${field}: ${list.join(", ")}`,
  )

  errors.value = messages.length > 0 ? messages : [data?.message ?? t("backend.saveFailed")]
}

async function onSubmit(): Promise<void> {
  if (saving.value) return

  saving.value = true
  errors.value = []

  try {
    if (id.value) {
      await update({
        id: id.value,
        data: {
          name: name.value,
          feature_expenses: featureExpenses.value,
          feature_logbook: featureLogbook.value,
        },
      })
    } else {
      await create({ data: { name: name.value, email: email.value } })
    }

    toasts.push("success", editing.value ? t("backend.saved") : t("backend.created"))
    await router.push({ name: "backend-accounts" })
  } catch (error: unknown) {
    refuse(error)
  } finally {
    saving.value = false
  }
}

async function onDestroy(): Promise<void> {
  if (!id.value) return
  if (!(await confirmDialog(t("backend.confirmDeleteAccount")))) return

  try {
    await destroy({ id: id.value })
    toasts.push("success", t("backend.accountDeleted"))
    await router.push({ name: "backend-accounts" })
  } catch {
    toasts.push("error", t("backend.accountDeleteFailed"))
  }
}
</script>

<template>
  <div id="backend-account-form">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="account-form-title">
        {{ editing ? t("backend.accounts.edit", { name: account?.name ?? "" }) : t("backend.accounts.new") }}
      </h1>

      <RouterLink v-slot="{ href, navigate }" :to="{ name: 'backend-accounts' }" custom>
        <UiButton as="a" :href="href" data-test="back" @click="navigate">
          {{ t("backend.back") }}
        </UiButton>
      </RouterLink>
    </div>

    <p v-if="loading" class="mt-4" data-test="loading">{{ t("backend.loading") }}</p>
    <UiAlert v-else-if="failed" variant="danger" class="mt-4" data-test="error">
      {{ t("backend.loadFailed") }}
    </UiAlert>

    <form v-else class="mt-4" novalidate @submit.prevent="onSubmit">
      <UiAlert v-if="errors.length > 0" variant="danger" data-test="form-errors">
        <ul>
          <li v-for="message in errors" :key="message">{{ message }}</li>
        </ul>
      </UiAlert>

      <div class="grid grid-cols-12 gap-4">
        <div class="col-span-12 md:col-span-6">
          <UiFormGroup :label="t('backend.columns.name')">
            <UiInput v-model="name" data-test="name" />
          </UiFormGroup>
        </div>

        <!-- The account cannot exist without a user, so the first one comes
             with it. Afterwards the users have their own screen. -->
        <div v-if="!editing" class="col-span-12 md:col-span-6">
          <UiFormGroup :label="t('backend.accounts.firstUser')">
            <UiInput v-model="email" type="email" data-test="email" />
          </UiFormGroup>
        </div>
      </div>

      <template v-if="editing">
        <label class="mb-2 flex cursor-pointer items-center gap-2">
          <input v-model="featureExpenses" type="checkbox" data-test="feature-expenses" />
          <span>{{ t("backend.accounts.expenses") }}</span>
        </label>

        <label class="mb-4 flex cursor-pointer items-center gap-2">
          <input v-model="featureLogbook" type="checkbox" data-test="feature-logbook" />
          <span>{{ t("backend.accounts.logbook") }}</span>
        </label>
      </template>

      <UiFormActions
        :save-label="t('backend.save')"
        :cancel-label="t('backend.cancel')"
        :busy="saving"
        @cancel="router.push({ name: 'backend-accounts' })"
      />

      <UiButton
        v-if="editing"
        class="mt-4"
        variant="danger"
        type="button"
        data-test="destroy"
        @click="onDestroy"
      >
        {{ t("backend.delete") }}
      </UiButton>
    </form>
  </div>
</template>

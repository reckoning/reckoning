<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import {
  useBackendUser,
  useBackendAccounts,
  useCreateBackendUser,
  useUpdateBackendUser,
  useDestroyBackendUser,
} from "@/services/api/services/backend/backend"
import { useToastsStore } from "@/stores/toasts"
import { confirmDialog } from "@/lib/confirm"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiButton from "@/components/ui/UiButton.vue"
import UiFormActions from "@/components/ui/UiFormActions.vue"
import UiFormGroup from "@/components/ui/UiFormGroup.vue"
import UiInput from "@/components/ui/UiInput.vue"

// `backend/users/{new,edit}`: an address, the admin flag, and — when creating
// — the account the user belongs to. The server-rendered form never asked for
// that and permitted no `account`, so its create could not pass `User`'s own
// validation: the button had been decoration. The password is never set here;
// the user gets a confirmation mail and picks their own.
const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const toasts = useToastsStore()

const id = computed(() => (route.params.id ? String(route.params.id) : undefined))
const editing = computed(() => id.value !== undefined)

const { data: user, isPending, isError } = useBackendUser(
  computed(() => id.value ?? ""),
  { query: { enabled: computed(() => editing.value) } },
)
const { data: accounts } = useBackendAccounts(
  { perPage: "all" },
  { query: { enabled: computed(() => !editing.value) } },
)
const { mutateAsync: create } = useCreateBackendUser()
const { mutateAsync: update } = useUpdateBackendUser()
const { mutateAsync: destroy } = useDestroyBackendUser()

const email = ref("")
const admin = ref(false)
const accountId = ref("")
const errors = ref<string[]>([])
const saving = ref(false)

watch(
  user,
  (current) => {
    if (!current) return

    email.value = current.email
    admin.value = current.admin ?? false
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
      await update({ id: id.value, data: { email: email.value, admin: admin.value } })
    } else {
      await create({
        data: { email: email.value, admin: admin.value, account_id: accountId.value },
      })
    }

    toasts.push("success", editing.value ? t("backend.saved") : t("backend.created"))
    await router.push({ name: "backend-users" })
  } catch (error: unknown) {
    refuse(error)
  } finally {
    saving.value = false
  }
}

async function onDestroy(): Promise<void> {
  if (!id.value) return
  if (!(await confirmDialog(t("backend.confirmDeleteUser")))) return

  try {
    await destroy({ id: id.value })
    toasts.push("success", t("backend.userDeleted"))
    await router.push({ name: "backend-users" })
  } catch {
    toasts.push("error", t("backend.userDeleteFailed"))
  }
}
</script>

<template>
  <div id="backend-user-form">
    <div class="flex flex-wrap items-start gap-4">
      <h1 class="grow" data-test="user-form-title">
        {{ editing ? t("backend.users.edit", { email: user?.email ?? "" }) : t("backend.users.new") }}
      </h1>

      <RouterLink v-slot="{ href, navigate }" :to="{ name: 'backend-users' }" custom>
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
          <UiFormGroup :label="t('backend.columns.email')">
            <UiInput v-model="email" type="email" data-test="email" />
          </UiFormGroup>
        </div>

        <!-- A user without an account is not a user `User` will save, and
             which account it is cannot be guessed from here. -->
        <div v-if="!editing" class="col-span-12 md:col-span-6">
          <UiFormGroup :label="t('backend.columns.account')">
            <UiInput v-model="accountId" as="select" data-test="user-account">
              <option value="">{{ t("backend.users.pickAccount") }}</option>
              <option v-for="account in accounts ?? []" :key="account.id" :value="account.id">
                {{ account.name }}
              </option>
            </UiInput>
          </UiFormGroup>
        </div>
      </div>

      <label class="mb-4 flex cursor-pointer items-center gap-2">
        <input v-model="admin" type="checkbox" data-test="admin" />
        <span>{{ t("backend.columns.admin") }}</span>
      </label>

      <UiFormActions
        :save-label="t('backend.save')"
        :cancel-label="t('backend.cancel')"
        :busy="saving"
        @cancel="router.push({ name: 'backend-users' })"
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

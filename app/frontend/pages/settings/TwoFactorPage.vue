<script setup lang="ts">
import { ref, onMounted } from "vue"
import { useI18n } from "vue-i18n"
import {
  createOtpEnrollment,
  enableOtp,
  disableOtp,
  regenerateOtpBackupCodes,
} from "@/services/api/services/otp/otp"
import { useCurrentUserStore } from "@/stores/currentUser"

const { t } = useI18n()
const currentUser = useCurrentUserStore()

const enabled = ref(currentUser.user?.otpRequired === true)
const provisioningUri = ref<string | undefined>()
const codes = ref<string[] | undefined>()
const otpToken = ref("")
const failed = ref(false)
const busy = ref(false)

// The QR code is an SVG served straight from the API rather than JSON, so it
// is rendered by URL instead of through the generated client.
const qrcodeUrl = "/api/v1/me/otp/qrcode"

async function startEnrollment(): Promise<void> {
  const enrollment = await createOtpEnrollment()
  provisioningUri.value = enrollment.provisioningUri
}

onMounted(async () => {
  if (!enabled.value) await startEnrollment()
})

async function enable(): Promise<void> {
  failed.value = false
  busy.value = true

  try {
    const result = await enableOtp({ otp_attempt: otpToken.value })
    codes.value = result.backupCodes
    enabled.value = true
    otpToken.value = ""
    await currentUser.refresh()
  } catch {
    failed.value = true
  } finally {
    busy.value = false
  }
}

async function disable(): Promise<void> {
  failed.value = false
  busy.value = true

  try {
    await disableOtp({ otp_attempt: otpToken.value })
    enabled.value = false
    codes.value = undefined
    otpToken.value = ""
    await currentUser.refresh()
    await startEnrollment()
  } catch {
    failed.value = true
  } finally {
    busy.value = false
  }
}

async function regenerate(): Promise<void> {
  failed.value = false
  busy.value = true

  try {
    const result = await regenerateOtpBackupCodes()
    codes.value = result.backupCodes
  } catch {
    failed.value = true
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div id="two-factor">
    <h1 data-test="two-factor-title">
      {{ t("twoFactor.title") }}
    </h1>

    <p v-if="failed" data-test="two-factor-failed" class="mt-4 text-danger-text">
      {{ t("twoFactor.failed") }}
    </p>

    <!-- Shown once, right after enabling or regenerating: the API returns the
         codes in the clear and never again. -->
    <div v-if="codes" class="mb-6" data-test="backup-codes">
      <p class="mb-2">{{ t("twoFactor.backupExplain") }}</p>
      <pre class="max-w-sm rounded-bs border border-rule-strong bg-surface-muted p-3 text-small">{{ codes.join("\n") }}</pre>
    </div>

    <template v-if="enabled">
      <p class="mb-4" data-test="two-factor-enabled">{{ t("twoFactor.disableExplain") }}</p>

      <button
        type="button"
        data-test="regenerate-codes"
        :disabled="busy"
        class="mb-6 rounded-bs border border-warning-border bg-warning px-3 py-1.5 text-white disabled:opacity-65"
        @click="regenerate"
      >
        {{ t("twoFactor.backupCodes") }}
      </button>

      <form class="max-w-sm" @submit.prevent="disable">
        <input
          v-model="otpToken"
          type="text"
          inputmode="numeric"
          autocomplete="one-time-code"
          :placeholder="t('twoFactor.otpToken')"
          data-test="otp-token"
          class="mb-3 block w-full rounded-bs border border-field-border px-3 py-1.5 text-field shadow-[inset_0_1px_1px_rgba(0,0,0,0.075)] placeholder:text-placeholder focus:border-field-focus focus:outline-none"
        />
        <button
          type="submit"
          data-test="disable-otp"
          :disabled="busy"
          class="rounded-bs-lg border border-brand-border bg-brand px-4 py-2.5 text-lg text-white hover:bg-brand-hover disabled:opacity-65"
        >
          {{ t("twoFactor.disable") }}
        </button>
      </form>
    </template>

    <template v-else>
      <p class="mb-4">{{ t("twoFactor.enableExplain") }}</p>

      <img :src="qrcodeUrl" alt="" class="mb-3 h-48 w-48" data-test="otp-qrcode" />

      <pre
        v-if="provisioningUri"
        class="mb-4 max-w-lg overflow-x-auto rounded-bs border border-rule-strong bg-surface-muted p-3 text-small"
        data-test="provisioning-uri"
        >{{ provisioningUri }}</pre
      >

      <form class="max-w-sm" @submit.prevent="enable">
        <input
          v-model="otpToken"
          type="text"
          inputmode="numeric"
          autocomplete="one-time-code"
          :placeholder="t('twoFactor.otpToken')"
          data-test="otp-token"
          class="mb-3 block w-full rounded-bs border border-field-border px-3 py-1.5 text-field shadow-[inset_0_1px_1px_rgba(0,0,0,0.075)] placeholder:text-placeholder focus:border-field-focus focus:outline-none"
        />
        <button
          type="submit"
          data-test="enable-otp"
          :disabled="busy"
          class="rounded-bs-lg border border-brand-border bg-brand px-4 py-2.5 text-lg text-white hover:bg-brand-hover disabled:opacity-65"
        >
          {{ t("twoFactor.enable") }}
        </button>
      </form>
    </template>
  </div>
</template>

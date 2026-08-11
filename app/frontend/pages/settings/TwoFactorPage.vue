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
  <div class="px-4 py-6">
    <h1 class="mb-4 text-[24px] font-medium" data-test="two-factor-title">
      {{ t("twoFactor.title") }}
    </h1>

    <p v-if="failed" data-test="two-factor-failed" class="mb-4 text-[14px] text-[#a94442]">
      {{ t("twoFactor.failed") }}
    </p>

    <!-- Shown once, right after enabling or regenerating: the API returns the
         codes in the clear and never again. -->
    <div v-if="codes" class="mb-6" data-test="backup-codes">
      <p class="mb-2 text-[14px]">{{ t("twoFactor.backupExplain") }}</p>
      <pre class="max-w-sm rounded border border-field-border bg-[#f5f5f5] p-3 text-[13px]">{{ codes.join("\n") }}</pre>
    </div>

    <template v-if="enabled">
      <p class="mb-4 text-[14px]" data-test="two-factor-enabled">{{ t("twoFactor.disableExplain") }}</p>

      <button
        type="button"
        data-test="regenerate-codes"
        :disabled="busy"
        class="mb-6 rounded border border-[#eea236] bg-[#f0ad4e] px-4 py-2 text-[14px] text-white disabled:opacity-65"
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
          class="mb-3 block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
        <button
          type="submit"
          data-test="disable-otp"
          :disabled="busy"
          class="rounded-md border border-brand-border bg-brand px-4 py-[10px] text-[18px] text-white disabled:opacity-65"
        >
          {{ t("twoFactor.disable") }}
        </button>
      </form>
    </template>

    <template v-else>
      <p class="mb-4 text-[14px]">{{ t("twoFactor.enableExplain") }}</p>

      <img :src="qrcodeUrl" alt="" class="mb-3 h-48 w-48" data-test="otp-qrcode" />

      <pre
        v-if="provisioningUri"
        class="mb-4 max-w-lg overflow-x-auto rounded border border-field-border bg-[#f5f5f5] p-3 text-[12px]"
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
          class="mb-3 block w-full rounded border border-field-border p-[10px] text-[16px] text-field placeholder:text-[#999] focus:border-[#66afe9] focus:outline-none"
        />
        <button
          type="submit"
          data-test="enable-otp"
          :disabled="busy"
          class="rounded-md border border-brand-border bg-brand px-4 py-[10px] text-[18px] text-white disabled:opacity-65"
        >
          {{ t("twoFactor.enable") }}
        </button>
      </form>
    </template>
  </div>
</template>

<script setup lang="ts">
import { useToastsStore } from "@/stores/toasts"

const toasts = useToastsStore()

const levelClasses: Record<string, string> = {
  success: "bg-green-600",
  info: "bg-blue-600",
  error: "bg-red-600",
}
</script>

<template>
  <div class="fixed bottom-4 right-4 z-50 flex w-80 flex-col gap-2" data-testid="toasts">
    <div
      v-for="toast in toasts.toasts"
      :key="toast.id"
      class="flex items-start gap-3 rounded px-4 py-3 text-white shadow-lg"
      :class="levelClasses[toast.level]"
      role="status"
    >
      <span class="grow text-sm">{{ toast.message }}</span>
      <button
        type="button"
        class="text-sm opacity-80 hover:opacity-100"
        aria-label="Dismiss"
        @click="toasts.dismiss(toast.id)"
      >
        ×
      </button>
    </div>
  </div>
</template>

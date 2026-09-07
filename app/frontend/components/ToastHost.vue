<script setup lang="ts">
import { useToastsStore } from "@/stores/toasts"

const toasts = useToastsStore()

// The server-rendered app shows its flashes as noty notifications in the top
// right corner, flat-filled with white text. Same place, same shape, in the
// semantic colours the tokens carry.
const levelClasses: Record<string, string> = {
  success: "bg-success",
  info: "bg-info",
  error: "bg-danger",
}
</script>

<template>
  <div
    class="fixed top-[60px] right-2 z-200 flex w-80 max-w-[calc(100vw-1rem)] flex-col gap-1 md:top-2"
    data-test="toasts"
  >
    <div
      v-for="toast in toasts.toasts"
      :key="toast.id"
      class="flex items-start gap-3 px-4 py-3 text-white shadow-[0_2px_6px_rgba(0,0,0,0.2)]"
      :class="levelClasses[toast.level]"
      role="status"
    >
      <span class="grow">{{ toast.message }}</span>
      <button
        type="button"
        class="text-lg leading-none opacity-80 hover:opacity-100"
        aria-label="Dismiss"
        @click="toasts.dismiss(toast.id)"
      >
        ×
      </button>
    </div>
  </div>
</template>

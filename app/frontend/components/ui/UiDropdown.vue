<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from "vue"

// `.dropdown` with Bootstrap's menu: absolutely positioned, its own border and
// shadow, and the `inset 4px 0 0` marker `partials/_nav.scss` puts on the
// active and hovered entry.
withDefaults(defineProps<{align?: "left" | "right"}>(), {align: "left"})

const open = ref(false)
const root = ref<HTMLElement | null>(null)

function close(): void {
  open.value = false
}

// A click anywhere else closes it, the way Bootstrap's own dropdowns do.
function onDocumentClick(event: MouseEvent): void {
  if (!root.value?.contains(event.target as Node)) close()
}

onMounted(() => document.addEventListener("click", onDocumentClick))
onBeforeUnmount(() => document.removeEventListener("click", onDocumentClick))

defineExpose({close})
</script>

<template>
  <div ref="root" class="relative inline-flex">
    <slot name="toggle" :open="open" :toggle="() => (open = !open)" />

    <ul
      v-show="open"
      class="absolute top-full z-50 mt-0.5 min-w-40 list-none rounded-bs border border-ink/15 bg-surface py-1 shadow-[0_6px_12px_rgba(0,0,0,0.175)]"
      :class="align === 'right' ? 'right-0' : 'left-0'"
      role="menu"
      @click="close"
    >
      <slot name="menu" />
    </ul>
  </div>
</template>

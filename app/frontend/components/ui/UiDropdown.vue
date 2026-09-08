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
      class="bs-dropdown-menu absolute top-full z-50 list-none"
      :class="align === 'right' ? 'right-0' : 'left-0'"
      role="menu"
      @click="close"
    >
      <slot name="menu" />
    </ul>
  </div>
</template>

<script setup lang="ts">
// `.nav-tabs` as the preview used them: the active tab joins the panel below
// it by painting over the shared border.
interface Tab {
  key: string
  label: string
}

defineProps<{tabs: Tab[]; active: string}>()

const emit = defineEmits<{select: [string]}>()
</script>

<template>
  <ul class="flex list-none border-b border-rule-strong">
    <li v-for="tab in tabs" :key="tab.key" class="-mb-px">
      <button
        type="button"
        class="mr-0.5 block rounded-t-bs border border-transparent px-[15px] py-2.5 leading-[1.428571429]"
        :class="
          tab.key === active
            ? 'border-rule-strong border-b-surface bg-surface text-field'
            : 'text-brand hover:bg-rule'
        "
        :data-test="`tab-${tab.key}`"
        @click="emit('select', tab.key)"
      >
        {{ tab.label }}
      </button>
    </li>
  </ul>
</template>

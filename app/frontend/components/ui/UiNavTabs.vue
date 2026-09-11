<script setup lang="ts">
// `.nav-tabs` as the server-rendered screens had them: the chosen tab is a
// white card with a border on three sides, sitting on the row's own line,
// which it paints over along its lower edge.
//
// The border colour belongs to the state, not to the base: Tailwind resolves
// two utilities for one property by their order in the stylesheet, not by the
// order they are written in, and `border-transparent` in the base was
// beating `border-rule-strong` here — leaving the chosen tab with no card at
// all, only a gap in the line.
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
        class="mr-0.5 block rounded-t-bs border px-[15px] py-2.5 leading-[1.428571429]"
        :class="
          tab.key === active
            ? 'border-rule-strong border-b-surface bg-surface text-field'
            : 'border-transparent text-brand hover:border-rule hover:border-b-rule-strong'
        "
        :data-test="`tab-${tab.key}`"
        @click="emit('select', tab.key)"
      >
        {{ tab.label }}
      </button>
    </li>
  </ul>
</template>

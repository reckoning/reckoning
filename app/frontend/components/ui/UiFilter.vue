<script setup lang="ts">
import UiDropdown from "./UiDropdown.vue"
import UiDropdownItem from "./UiDropdownItem.vue"

// `shared/tables/_filter`: a dropdown button naming the filter, the chosen
// value in bold beside it, and — once something is chosen — a red reset button
// glued to its left as one button group.
interface Option {
  value: string
  label: string
}

const props = defineProps<{
  label: string
  modelValue: string
  options: Option[]
  resetTitle: string
  align?: "left" | "right"
  test?: string
}>()

const emit = defineEmits<{"update:modelValue": [string]}>()

function chosenLabel(): string {
  return props.options.find((option) => option.value === props.modelValue)?.label ?? ""
}
</script>

<template>
  <div class="flex">
    <button
      v-if="modelValue"
      type="button"
      class="rounded-l-bs border border-danger-border bg-danger px-3 py-1.5 text-base leading-[1.428571429] text-white hover:border-danger-hover-border hover:bg-danger-hover"
      :title="resetTitle"
      :data-test="test ? `${test}-reset` : undefined"
      @click="emit('update:modelValue', '')"
    >
      <i class="fa fa-times"></i>
    </button>

    <UiDropdown :align="align ?? 'left'">
      <template #toggle="{ toggle }">
        <button
          type="button"
          class="border border-field-border bg-surface px-3 py-1.5 text-base leading-[1.428571429] text-ink hover:border-control-hover-border hover:bg-control-hover"
          :class="modelValue ? 'rounded-r-bs border-l-0' : 'rounded-bs'"
          :data-test="test"
          @click="toggle"
        >
          {{ label }}
          <strong v-if="modelValue">{{ chosenLabel() }}</strong>
          <span class="bs-caret"></span>
        </button>
      </template>

      <template #menu>
        <UiDropdownItem
          v-for="option in options"
          :key="option.value"
          :active="option.value === modelValue"
          :data-test="test ? `${test}-${option.value}` : undefined"
          @click="emit('update:modelValue', option.value)"
        >
          {{ option.label }}
        </UiDropdownItem>
      </template>
    </UiDropdown>
  </div>
</template>

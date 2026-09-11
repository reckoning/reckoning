<script setup lang="ts">
// The month the calendar is showing, and the four buttons that move it: back,
// a native month picker behind a calendar icon, today, forward.

import {computed, ref} from "vue"
import {useI18n} from "vue-i18n"
import UiButton from "@/components/ui/UiButton.vue"

const props = defineProps<{
  month: string
  businessDays: number
  todayLabel: string
  weekDaysLabel: string
  monthLabels: string[]
}>()

const {t} = useI18n()

const previousLabel = computed(() => t("timesheet.previousDay"))
const nextLabel = computed(() => t("timesheet.nextDay"))
const pickMonthLabel = computed(() => t("timesheet.pickDate"))

const emit = defineEmits<{
  prev: []
  next: []
  today: []
  jump: [month: string]
}>()

const monthLabel = computed(() => {
  const [y, m] = props.month.split("-").map(Number)
  const name = props.monthLabels[(m ?? 1) - 1] ?? ""
  return `${name} ${y}`
})

const isToday = computed(() => {
  const now = new Date()
  const [y, m] = props.month.split("-").map(Number)
  return now.getFullYear() === y && now.getMonth() + 1 === m
})

const monthInputValue = computed(() => props.month.slice(0, 7))

const hiddenInputRef = ref<HTMLInputElement | null>(null)

function openPicker() {
  const el = hiddenInputRef.value
  if (!el) return
  // Modern browsers: showPicker() opens the native month picker
  // without focusing the visible button. Older browsers fall back
  // to focusing the input which also opens the picker.
  if (typeof el.showPicker === "function") {
    el.showPicker()
  } else {
    el.focus()
    el.click()
  }
}

function onMonthInput(e: Event) {
  const value = (e.target as HTMLInputElement).value
  if (!value) return
  emit("jump", `${value}-01`)
}
</script>

<template>
  <div class="flex flex-wrap items-center justify-between gap-2">
    <h2>
      <span>{{ monthLabel }}</span>
      <small> ({{ businessDays }} {{ weekDaysLabel }}) </small>
    </h2>

    <div class="bs-btn-group">
      <UiButton :title="previousLabel" @click="emit('prev')">
        <i class="fa fa-chevron-left" aria-hidden="true"></i>
      </UiButton>

      <!-- The input is a sibling rather than a child of the button: it is
           what `showPicker()` opens, and a form control inside a button is a
           second control inside the first. -->
      <span class="relative inline-flex">
        <UiButton class="rounded-none" :title="pickMonthLabel" @click="openPicker">
          <i class="fa fa-calendar" aria-hidden="true"></i>
        </UiButton>
        <input
          ref="hiddenInputRef"
          type="month"
          :value="monthInputValue"
          class="month-picker-input"
          tabindex="-1"
          aria-hidden="true"
          @change="onMonthInput"
        />
      </span>

      <UiButton :disabled="isToday" @click="emit('today')">
        {{ todayLabel }}
      </UiButton>

      <UiButton :title="nextLabel" @click="emit('next')">
        <i class="fa fa-chevron-right" aria-hidden="true"></i>
      </UiButton>
    </div>
  </div>
</template>

<style scoped>
/* Hide the native `<input type="month">` UI but keep it functional
 * — the visible calendar icon triggers showPicker() programmatically.
 * Negative z-index + opacity:0 + pointer-events:none keeps it from
 * interfering with the surrounding btn-group layout. */
.month-picker-input {
  position: absolute;
  inset: 0;
  opacity: 0;
  pointer-events: none;
  border: 0;
  background: transparent;
  z-index: -1;
}
</style>

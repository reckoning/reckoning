<script setup lang="ts">
// Markup mirrors the legacy `app/views/templates/timers/month.html.erb`
// so the existing Bootstrap 3 `.btn`/`.resource-nav` styles and the
// `_calendar.scss` partial apply.

import {computed, ref} from "vue"

const props = defineProps<{
  month: string
  businessDays: number
  todayLabel: string
  weekDaysLabel: string
  monthLabels: string[]
}>()

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
  <div class="row">
    <div class="col-xs-12 col-md-6">
      <h2>
        <span>{{ monthLabel }}</span>
        <small> ({{ businessDays }} {{ weekDaysLabel }}) </small>
      </h2>
    </div>
    <div class="col-xs-12 col-md-6">
      <div class="pull-right resource-nav">
        <div class="btn-group btn-group-justified-responsive resource-nav">
          <a class="btn btn-default" role="button" @click.prevent="emit('prev')">
            <i class="fa fa-chevron-left" aria-hidden="true"></i>
          </a>
          <a class="btn btn-default month-picker-trigger" role="button" @click.prevent="openPicker">
            <i class="fa fa-calendar" aria-hidden="true"></i>
            <input
              ref="hiddenInputRef"
              type="month"
              :value="monthInputValue"
              class="month-picker-input"
              tabindex="-1"
              aria-hidden="true"
              @change="onMonthInput"
            />
          </a>
          <a
            class="btn btn-default"
            role="button"
            :class="{disabled: isToday}"
            @click.prevent="!isToday && emit('today')"
          >
            {{ todayLabel }}
          </a>
          <a class="btn btn-default" role="button" @click.prevent="emit('next')">
            <i class="fa fa-chevron-right" aria-hidden="true"></i>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.month-picker-trigger {
  position: relative;
}
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

<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue"
import { useIsFetching } from "@tanstack/vue-query"
import { useRouter } from "vue-router"

// Turbo Drive's progress bar, which every server-rendered navigation shows:
// a line across the top of the window in the nav's active colour. Turbo holds
// it back for half a second, so a quick answer never makes it flash, then
// trickles towards the end without ever arriving until the work is done.
const DELAY = 500
const TRICKLE = 300

const fetching = useIsFetching()
const navigating = ref(0)

const router = useRouter()
const stopBefore = router.beforeEach(() => {
  navigating.value += 1
})
const stopAfter = router.afterEach(() => {
  navigating.value = Math.max(0, navigating.value - 1)
})
const stopError = router.onError(() => {
  navigating.value = Math.max(0, navigating.value - 1)
})

const busy = computed(() => fetching.value > 0 || navigating.value > 0)

const visible = ref(false)
const done = ref(false)
const value = ref(0)

let delayTimer: ReturnType<typeof setTimeout> | undefined
let trickleTimer: ReturnType<typeof setInterval> | undefined

function clearTimers(): void {
  clearTimeout(delayTimer)
  clearInterval(trickleTimer)
  delayTimer = undefined
  trickleTimer = undefined
}

function start(): void {
  clearTimers()

  // Work that starts again inside the completion fade finds the bar still
  // sitting at the end: it goes away first, so the next delay starts from
  // nothing rather than jumping back from full width.
  if (done.value) {
    visible.value = false
    value.value = 0
  }

  done.value = false

  delayTimer = setTimeout(() => {
    visible.value = true
    value.value = 10
    trickleTimer = setInterval(() => {
      // Approaches the end without reaching it: the remaining distance is
      // what shrinks, so a slow request keeps moving.
      value.value += (100 - value.value) / 10
    }, TRICKLE)
  }, DELAY)
}

function finish(): void {
  clearTimers()

  if (!visible.value) return

  value.value = 100
  done.value = true
  delayTimer = setTimeout(() => {
    visible.value = false
    value.value = 0
  }, 300)
}

watch(busy, (isBusy) => (isBusy ? start() : finish()), {immediate: true})

onBeforeUnmount(() => {
  clearTimers()
  stopBefore()
  stopAfter()
  stopError()
})
</script>

<template>
  <div
    v-if="visible"
    class="fixed top-0 left-0 z-[2147483647] h-[3px] bg-brand"
    :class="done ? 'opacity-0 transition-opacity duration-150 delay-150' : 'transition-[width] duration-300 ease-out'"
    :style="{width: `${value}%`}"
    role="progressbar"
    aria-hidden="true"
    data-test="loading-bar"
  ></div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from "vue"
import { useI18n } from "vue-i18n"

// pdf.js and its worker are about 1.5 MB, so they are imported when a viewer
// actually mounts rather than shipped with the bundle — the same reason the
// server-rendered pages loaded them behind an event. Rendering mirrors what
// `app/pdf_viewer.coffee` did: every page onto its own canvas at scale 2, in
// order.
const props = defineProps<{ src: string }>()

const { t } = useI18n()

const pages = ref<HTMLDivElement>()
const state = ref<"loading" | "ready" | "failed">("loading")

type PdfJs = typeof import("pdfjs-dist")

let library: Promise<PdfJs> | undefined
let generation = 0

function pdfjs(): Promise<PdfJs> {
  library ??= (async () => {
    const lib = await import("pdfjs-dist")
    const { default: workerUrl } = await import("pdfjs-dist/build/pdf.worker.min.mjs?url")
    lib.GlobalWorkerOptions.workerSrc = workerUrl

    return lib
  })()

  return library
}

async function render(): Promise<void> {
  const host = pages.value
  if (!host) return

  // A second render — a new src, or a remount — must not interleave its
  // canvases with the one still running.
  const mine = ++generation

  state.value = "loading"
  host.replaceChildren()

  try {
    const lib = await pdfjs()
    const document_ = await lib.getDocument(props.src).promise

    for (let number = 1; number <= document_.numPages; number += 1) {
      if (mine !== generation) return

      const page = await document_.getPage(number)
      const viewport = page.getViewport({ scale: 2 })
      const canvas = document.createElement("canvas")
      canvas.height = viewport.height
      canvas.width = viewport.width
      canvas.className = "mb-2 w-full border border-rule"

      const context = canvas.getContext("2d")
      if (!context) throw new Error("no 2d context")

      await page.render({ canvasContext: context, viewport }).promise

      if (mine !== generation) return

      host.append(canvas)
    }

    state.value = "ready"
  } catch {
    if (mine === generation) state.value = "failed"
  }
}

onMounted(render)
watch(() => props.src, render)
onBeforeUnmount(() => {
  generation += 1
})
</script>

<template>
  <div>
    <p v-if="state === 'loading'" class="text-sm text-muted" data-test="pdf-loading">
      {{ t("pdf.loading") }}
    </p>
    <p v-else-if="state === 'failed'" class="text-sm text-danger" data-test="pdf-failed">
      {{ t("pdf.failed") }}
    </p>

    <div ref="pages" data-test="pdf-pages"></div>
  </div>
</template>

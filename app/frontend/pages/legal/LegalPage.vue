<script setup lang="ts">
import { computed } from "vue"
import { useI18n } from "vue-i18n"
import { legalDocument } from "@/content/legal"

// One layout for the three legal documents: a headline, then sections of
// prose. The text itself lives in `content/legal.ts`.
const props = defineProps<{ document: string }>()

const { locale } = useI18n()

const doc = computed(() => legalDocument(props.document, locale.value))
</script>

<template>
  <article class="mx-auto max-w-[780px]" :data-test="`legal-${document}`">
    <div class="bs-page-header">
      <h1>
        {{ doc.title }}
        <br v-if="doc.subtitle" />
        <small v-if="doc.subtitle">{{ doc.subtitle }}</small>
      </h1>
    </div>

    <section v-for="section in doc.sections" :key="section.title" class="mb-6">
      <h2 class="text-[length:var(--text-h3)]">{{ section.title }}</h2>

      <p v-for="(paragraph, index) in section.paragraphs" :key="index" class="mb-2.5">
        {{ paragraph }}
      </p>

      <ul v-if="section.list" class="mb-2.5 list-disc pl-5">
        <li v-for="(entry, index) in section.list" :key="index">{{ entry }}</li>
      </ul>

      <dl v-if="section.rows" class="mb-2.5">
        <template v-for="row in section.rows" :key="row.term">
          <dt class="font-bold">{{ row.term }}</dt>
          <dd class="mb-2.5">{{ row.description }}</dd>
        </template>
      </dl>
    </section>

    <p class="text-muted">{{ doc.updated }}</p>
  </article>
</template>

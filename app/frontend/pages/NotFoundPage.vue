<script setup lang="ts">
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"
import UiButton from "@/components/ui/UiButton.vue"

// `errors/not_found.html.erb` for the paths the SPA owns, which is all of
// them that are not the API or a PDF.
const { t } = useI18n()
</script>

<template>
  <div class="py-10 text-center" data-test="not-found">
    <h1>{{ t("notFound.title") }}</h1>
    <p class="mt-2 text-muted">{{ t("notFound.body") }}</p>

    <RouterLink v-slot="{ href, navigate }" :to="{ name: 'dashboard' }" custom>
      <UiButton as="a" variant="primary" class="mt-5" :href="href" @click="navigate">
        {{ t("notFound.home") }}
      </UiButton>
    </RouterLink>
  </div>
</template>

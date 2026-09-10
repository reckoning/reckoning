<script setup lang="ts">
import { RouterLink } from "vue-router"
import { useI18n } from "vue-i18n"

// `layouts/backend/_links`: the three areas side by side, wherever you are in
// the backend — reaching the accounts from the users should not have to go
// through the dashboard. Styled like `UiNavTabs`, which takes a click rather
// than a link and so cannot serve here.
const LINKS = [
  { name: "backend", label: "backend.nav.dashboard", test: "nav-backend-dashboard" },
  { name: "backend-accounts", label: "backend.nav.accounts", test: "nav-backend-accounts" },
  { name: "backend-users", label: "backend.nav.users", test: "nav-backend-users" },
] as const

const { t } = useI18n()
</script>

<template>
  <ul class="mb-4 flex list-none border-b border-rule-strong" data-test="backend-nav">
    <li v-for="link in LINKS" :key="link.name" class="-mb-px">
      <RouterLink v-slot="{ href, navigate, isActive }" :to="{ name: link.name }" custom>
        <a
          class="mr-0.5 block rounded-t-bs border border-transparent px-[15px] py-2.5 leading-[1.428571429]"
          :class="
            isActive
              ? 'border-rule-strong border-b-surface bg-surface text-field'
              : 'text-brand hover:bg-rule'
          "
          :href="href"
          :data-test="link.test"
          @click="navigate"
        >
          {{ t(link.label) }}
        </a>
      </RouterLink>
    </li>
  </ul>
</template>

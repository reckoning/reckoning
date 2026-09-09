<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useRoute, useRouter, RouterLink, RouterView } from "vue-router"
import { useI18n } from "vue-i18n"
import { useCurrentUserStore } from "@/stores/currentUser"
import { useAccount } from "@/services/api/services/account/account"
import AppProgress from "@/components/AppProgress.vue"
import ToastHost from "@/components/ToastHost.vue"
import UiAlert from "@/components/ui/UiAlert.vue"
import UiDropdown from "@/components/ui/UiDropdown.vue"
import UiDropdownDivider from "@/components/ui/UiDropdownDivider.vue"
import UiDropdownItem from "@/components/ui/UiDropdownItem.vue"

const { t } = useI18n()
const router = useRouter()
const route = useRoute()
const currentUser = useCurrentUserStore()

const { data: account } = useAccount({
  query: { enabled: computed(() => currentUser.signedIn) },
})

// The navigation is an aside on a wide screen and a drawer on a narrow one,
// the way `partials/_navbar-aside.scss` has it.
const drawerOpen = ref(false)

watch(() => route.fullPath, () => (drawerOpen.value = false))

async function signOut(): Promise<void> {
  await currentUser.signOut()
  await router.replace({ name: "login" })
}

const LINKS = [
  { name: "dashboard", label: "nav.home", test: "nav-home" },
  { name: "invoices", label: "nav.invoices", test: "nav-invoices" },
  { name: "offers", label: "nav.offers", test: "nav-offers" },
  { name: "projects", label: "nav.projects", test: "nav-projects" },
  { name: "customers", label: "nav.customers", test: "nav-customers" },
  { name: "timesheet", label: "nav.timesheet", test: "nav-timesheet" },
  { name: "expenses", label: "nav.expenses", test: "nav-expenses", feature: "expenses" },
] as const

// Expenses are an account feature, and `_links.html.erb` only prints the
// link where the ability allows it. Until the account has answered, the
// entry stays out rather than appearing and vanishing again.
const links = computed(() =>
  LINKS.filter((link) => !("feature" in link) || account.value?.featureExpenses === true),
)

const trial = computed(() => account.value?.trial)
</script>

<template>
  <div class="min-h-screen bg-surface text-ink">
    <AppProgress />

    <template v-if="currentUser.signedIn">
      <!-- Below the aside's breakpoint the navigation collapses to a bar with
           a toggle, and the links slide in from the left. -->
      <div
        class="bs-nav fixed inset-x-0 top-0 z-100 flex h-[50px] items-center border-b md:hidden"
      >
        <button
          type="button"
          class="flex h-[50px] w-[50px] flex-col items-center justify-center gap-1"
          :aria-label="t('nav.toggle')"
          data-test="nav-toggle"
          @click="drawerOpen = !drawerOpen"
        >
          <span v-for="bar in 3" :key="bar" class="block h-0.5 w-[22px] bg-nav-link"></span>
        </button>

        <RouterLink
          :to="{ name: 'dashboard' }"
          class="bs-nav-brand grow truncate pr-[50px] text-center font-brand text-nav-link"
        >
          {{ t("nav.brand") }}
        </RouterLink>
      </div>

      <nav
        class="bs-nav fixed inset-y-0 left-0 z-100 flex w-[85vw] flex-col overflow-y-auto border-r transition-[left] duration-500 md:left-0 md:w-1/6 min-[1800px]:w-[12.5%]"
        :class="drawerOpen ? 'left-0' : '-left-[85vw]'"
        data-test="main-nav"
      >
        <RouterLink
          :to="{ name: 'dashboard' }"
          class="bs-nav-brand hidden truncate font-brand text-nav-link hover:text-nav-link-hover md:block"
        >
          {{ t("nav.brand") }}
        </RouterLink>

        <!-- The user menu sits above the links, with the hairline the server
             -rendered aside draws under it. -->
        <UiDropdown class="!block border-b border-ink/10" align="left">
          <template #toggle="{ toggle }">
            <button
              type="button"
              class="bs-nav-user flex w-full items-center gap-1.5 text-left text-nav-link"
              data-test="user-menu"
              @click="toggle"
            >
              <span class="size-[30px] shrink-0 rounded-full border border-muted p-0.5">
                <img
                  v-if="currentUser.user?.avatar"
                  :src="currentUser.user.avatar"
                  alt=""
                  class="size-6 rounded-full"
                />
              </span>
              <span class="grow truncate text-sm" data-test="account">{{ currentUser.user?.email }}</span>
              <span class="bs-caret"></span>
            </button>
          </template>

          <template #menu>
            <UiDropdownItem>
              <a href="/settings" data-test="nav-account">{{ t("nav.account") }}</a>
            </UiDropdownItem>
            <UiDropdownItem>
              <RouterLink :to="{ name: 'two-factor' }" data-test="nav-two-factor">
                {{ t("nav.security") }}
              </RouterLink>
            </UiDropdownItem>
            <UiDropdownDivider />
            <UiDropdownItem>
              <!-- Most of the product is still server-rendered, and signing in
                   now lands here rather than there. Until phase C folds the
                   two navigations into one, this is the way across. -->
              <a href="/" data-test="nav-legacy">{{ t("nav.legacy") }}</a>
            </UiDropdownItem>
            <UiDropdownDivider />
            <UiDropdownItem>
              <button type="button" data-test="sign-out" @click="signOut">
                {{ t("nav.signOut") }}
              </button>
            </UiDropdownItem>
          </template>
        </UiDropdown>

        <ul class="list-none">
          <li v-for="link in links" :key="link.name">
            <RouterLink
              :to="{ name: link.name }"
              class="bs-nav-link text-nav-link"
              active-class="is-active"
              :data-test="link.test"
            >
              {{ t(link.label) }}
            </RouterLink>
          </li>
        </ul>
      </nav>

      <!-- The backdrop only exists while the drawer is out. -->
      <div
        v-if="drawerOpen"
        class="fixed inset-0 z-40 bg-ink/40 md:hidden"
        @click="drawerOpen = false"
      ></div>
    </template>

    <div
      :class="
        currentUser.signedIn
          ? 'px-4 pt-[70px] pb-5 md:ml-[16.666667%] md:pt-5 min-[1800px]:ml-[12.5%]'
          : 'px-4 py-5'
      "
    >
      <!-- Hinter der Anmeldeprüfung: die Kontodaten bleiben nach dem Abmelden
           im Cache der Query, und ein Banner auf dem Anmeldebildschirm wäre
           die Auskunft eines Kontos, das gerade niemand ist. -->
      <template v-if="currentUser.signedIn">
        <UiAlert v-if="trial?.active" variant="info" data-test="trial-banner">
          {{ t("trial.active", { count: trial.daysLeft ?? 0 }, trial.daysLeft ?? 0) }}
        </UiAlert>

        <UiAlert v-else-if="trial?.expired" variant="warning" data-test="trial-banner">
          {{ t("trial.expired") }}
        </UiAlert>
      </template>

      <RouterView />
    </div>

    <ToastHost />
  </div>
</template>

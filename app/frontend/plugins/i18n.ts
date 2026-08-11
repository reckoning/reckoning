import { createI18n } from "vue-i18n";
import en from "@/translations/en";
import de from "@/translations/de";

// Independent of i18n-js: the SPA ships its own bundles and reads the locale
// the Rails layout rendered, so both frontends agree during the migration.
function documentLocale(): string {
  return document.documentElement.lang || "en";
}

export const i18n = createI18n({
  legacy: false,
  locale: documentLocale(),
  fallbackLocale: "en",
  messages: { en, de },
});

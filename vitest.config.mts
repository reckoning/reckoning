import {defineConfig} from "vitest/config"
import vue from "@vitejs/plugin-vue"
import {fileURLToPath} from "node:url"

// Vitest config for the Vue islands. Deliberately does NOT load the
// vite-plugin-ruby integration (that needs the running Rails/Vite
// bridge) — only the Vue SFC compiler and a DOM environment.
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./app/frontend", import.meta.url)),
    },
  },
  test: {
    environment: "happy-dom",
    globals: true,
    include: ["app/frontend/**/*.spec.ts"],
  },
})

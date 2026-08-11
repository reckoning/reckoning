import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"
import tailwindcss from "@tailwindcss/vite"
import vue from "@vitejs/plugin-vue"
import { fileURLToPath } from "node:url"

export default defineConfig({
  plugins: [RubyPlugin(), tailwindcss(), vue()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./app/frontend", import.meta.url)),
    },
  },
})

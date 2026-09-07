import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"
import tailwindcss from "@tailwindcss/vite"
import vue from "@vitejs/plugin-vue"
import { fileURLToPath } from "node:url"

const devOrigins = [
  /^https?:\/\/(?:[^.]+\.)?localhost(?::\d+)?$/,
  /^https?:\/\/127\.0\.0\.1(?::\d+)?$/,
  /^https?:\/\/(?:[^.]+\.)?reckoning\.test(?::\d+)?$/,
]

export default defineConfig({
  plugins: [RubyPlugin(), tailwindcss(), vue()],
  // Rails serves the app from reckoning.test while Vite serves its assets from
  // its own port, and Vite only sends CORS headers to localhost by default.
  server: {
    allowedHosts: [".reckoning.test"],
    cors: { origin: devOrigins },
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./app/frontend", import.meta.url)),
    },
  },
})

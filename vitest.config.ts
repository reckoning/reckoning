import path from "path";
import { defineConfig } from "vitest/config";
import VuePlugin from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [VuePlugin()],
  define: {
    "process.env": {},
  },
  test: {
    include: ["app/frontend/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],
    globals: true,
    environment: "jsdom",
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./app/frontend"),
      "~": path.resolve(__dirname, "."),
    },
  },
});

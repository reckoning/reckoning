import { defineConfig, splitVendorChunkPlugin } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import VuePlugin from "@vitejs/plugin-vue";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    VuePlugin(),
    VitePWA({
      registerType: "autoUpdate",
      filename: "sw.js",
      useCredentials: true,
      scope: "/",
      workbox: {
        modifyURLPrefix: {
          "": "/vite/",
        },
        globPatterns: ["**/*.{js,css,html,ico,png,svg}"],
        clientsClaim: true,
        skipWaiting: true,
        navigateFallback: null,
      },
    }),
    splitVendorChunkPlugin(),
  ],
  build: {
    rollupOptions: {
      maxParallelFileReads: 5,
    },
    commonjsOptions: {
      requireReturnsDefault: true,
    },
  },
  define: {
    "process.env": {},
  },
});

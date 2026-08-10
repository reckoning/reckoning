import { defineConfig } from "orval";

export default defineConfig({
  api: {
    output: {
      namingConvention: "PascalCase",
      mode: "tags-split",
      workspace: "app/frontend/services/api",
      target: "./services",
      schemas: "./models",
      client: "vue-query",
      httpClient: "axios",
      clean: true,
      prettier: false,
      override: {
        mutator: {
          path: "../axiosClient.ts",
          name: "axiosClient",
        },
      },
    },
    input: {
      target: "./swagger/v1/schema.yaml",
    },
  },
});

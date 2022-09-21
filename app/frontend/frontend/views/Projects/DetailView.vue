<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8" v-if="project">
      <h1 class="text-2xl text-gray-900">{{ project.name }}</h1>

      {{ project }}
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onBeforeMount } from "vue";
import { useRoute, useRouter } from "vue-router";
import apiClient from "@/frontend/api";
import type { Project } from "@/frontend/api/client/models/Project";

const route = useRoute();
const router = useRouter();

const project = ref<Project | null>(null);

onBeforeMount(async () => {
  try {
    project.value = await apiClient.projects.getProject({
      id: route.params.id as string,
    });
  } catch (error) {
    router.push({ name: "projects" });
  }
});
</script>

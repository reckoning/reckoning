<template>
  <div class="py-6">
    <div v-if="project" class="mx-auto px-4 sm:px-6 md:px-8">
      <PageHeader :title="(project.name as string)" :breadcrumbs="breadcrumbs">
        <template #actions>
          <Btn :to="{ name: 'projects' }">Edit</Btn>
        </template>
      </PageHeader>

      <div>
        {{ project }}
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, onBeforeMount } from "vue";
import { useRoute, useRouter } from "vue-router";
import apiClient from "@/frontend/api";
import type { Project } from "@/frontend/api/client/models/Project";
import Btn from "@/frontend/components/DefaultButton.vue";
import PageHeader from "@/frontend/components/PageHeader.vue";

const route = useRoute();
const router = useRouter();

const project = ref<Project | null>(null);

const breadcrumbs = computed(() => {
  if (!project.value) {
    return [];
  }

  return [
    {
      name: "Projects",
      to: { name: "projects" },
    },
    {
      name: project.value.customerName as string,
      to: { name: "customer-detail", params: { id: "foo" } },
    },
    {
      name: project.value.name as string,
      to: { name: "project-detail", params: { id: project.value.id } },
    },
  ];
});

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

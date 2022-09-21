<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8">
      <h1 class="text-2xl text-gray-900">Projects</h1>

      <ul>
        <li v-for="customer in customers" :key="customer">
          {{ customer }}
          <ul>
            <li
              v-for="project in projectsForCustomer(customer)"
              :key="project.id"
            >
              -
              <router-link
                :to="{ name: 'project-detail', params: { id: project.id } }"
                >{{ project.name }}</router-link
              >
            </li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, computed } from "vue";
import type { Project } from "@/frontend/api/client/models/Project";
import apiClient from "@/frontend/api";

// Fetch Projects
const projects = ref<Project[] | []>([]);

const onlyUnique = (value, index, self) => self.indexOf(value) === index;

const projectsForCustomer = (customerName: string): Project[] =>
  projects.value.filter((project) => project.customerName === customerName);

const customers = computed(() =>
  projects.value.map((project) => project.customerName).filter(onlyUnique)
);

onMounted(async () => {
  try {
    projects.value = await apiClient.projects.getProjects();
  } catch (error) {
    // console.error(error)
  }
});
</script>

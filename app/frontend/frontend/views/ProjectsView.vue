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
              - {{ project.name }}
            </li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, computed } from 'vue'
import type { Project } from '@/frontend/api/client/models/Project'
import apiClient from '@/frontend/api'

// Fetch Projects
const projects = ref<Project[] | []>([])

const groupedProjects = computed(() =>
  projects.value.reduce((acc, project) => {
    const key = project.customerName
    if (!acc[key]) {
      acc[key] = []
    }
    acc[key].push(project)
    return acc
  }, {} as Record<string, Project[]>)
)

const onlyUnique = (value, index, self) => self.indexOf(value) === index

const projectsForCustomer = (customerName: string): Project[] =>
  projects.value.filter((project) => project.customerName == customerName)

const customers = computed(() =>
  projects.value.map((project) => project.customerName).filter(onlyUnique)
)

console.log(groupedProjects)

onMounted(async () => {
  try {
    projects.value = await apiClient.projects.getProjects()
  } catch (error) {
    // console.error(error)
  }
})
</script>

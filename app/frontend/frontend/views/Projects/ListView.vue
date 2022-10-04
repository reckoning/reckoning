<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8">
      <h1 class="text-2xl text-gray-900">Projects</h1>

      <div
        v-for="customer in customers"
        :key="customer"
        class="mt-8 flex flex-col"
      >
        <div class="-my-2 -mx-4 sm:-mx-6 lg:-mx-8">
          <div
            class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8"
          >
            <div class="shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
              <table class="min-w-full divide-y divide-gray-300">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 w-1/3 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6"
                    >
                      {{ customer }}
                    </th>
                    <th
                      scope="col"
                      class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                    >
                      Budget
                    </th>
                    <th
                      scope="col"
                      class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                    >
                      Hours
                    </th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                      <span class="sr-only">Edit</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 bg-white">
                  <tr
                    v-for="(project, index) in projectsForCustomer(customer)"
                    :key="project.id"
                    :class="[
                      index === 0 ? 'border-gray-300' : 'border-gray-200',
                      'border-t',
                    ]"
                  >
                    <td
                      class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6"
                    >
                      <router-link
                        :to="{
                          name: 'project-detail',
                          params: { id: project.id },
                        }"
                        >{{ project.name }}</router-link
                      >
                    </td>
                    <td
                      class="whitespace-nowrap px-3 py-4 text-sm text-gray-500"
                    >
                      {{ project.budget }}
                    </td>
                    <td
                      class="whitespace-nowrap px-3 py-4 text-sm text-gray-500"
                    >
                      {{ project.timerValues }}
                    </td>
                    <td
                      class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6"
                    >
                      <DropdownMenu />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, computed } from "vue";
import type { Project } from "@/frontend/api/client/models/Project";
import apiClient from "@/frontend/api";
import DropdownMenu from "@/frontend/components/DropdownMenu.vue";

// Fetch Projects
const projects = ref<Project[] | []>([]);

const projectsForCustomer = (customerName: string): Project[] =>
  projects.value.filter((project) => project.customerName === customerName);

const customers = computed((): string[] => {
  const customerNames = projects.value.map(
    (project: Project) => project.customerName as string
  );

  return customerNames.filter((name, index) => {
    return customerNames.indexOf(name) === index;
  });
});

onMounted(async () => {
  try {
    projects.value = await apiClient.projects.getProjects();
  } catch (error) {
    // console.error(error)
  }
});
</script>

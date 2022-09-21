<template>
  <router-link
    :to="{ name: props.routeName }"
    :active="active"
    :class="{
      'bg-gray-100 text-gray-900': active,
      'text-gray-600 hover:bg-gray-50 hover:text-gray-900': !active,
    }"
    class="group flex items-center px-2 py-2 font-medium rounded-md"
  >
    <slot />
  </router-link>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router";

export interface Props {
  routeName: string;
}

const route = useRoute();
const props = withDefaults(defineProps<Props>(), {});

const active = computed(() => {
  if (route.name === props.routeName) {
    return true;
  }

  return false;
});
</script>

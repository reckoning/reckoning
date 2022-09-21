import { ref } from "vue";
import { defineStore } from "pinia";

export default defineStore("App", () => {
  const navigationOpen = ref(false);

  function openNavigation() {
    navigationOpen.value = true;
  }

  function closeNavigation() {
    navigationOpen.value = false;
  }

  return { navigationOpen, openNavigation, closeNavigation };
});

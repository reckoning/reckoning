<template>
  <div class="mt-5 w-full">
    <div class="flex flex-row space-x-4 pt-3">
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="name"
          v-model="calculatorData.name"
          type="text"
          @input="saveCalculator"
        />
      </div>
      <div class="basis-1/3">
        <DateRangePicker
          :start="calculatorData.startDate"
          :end="calculatorData.endDate"
          @input="saveDateRange"
        />
      </div>
      <div class="basis-1/3 space-y-3 text-right">
        <button
          v-if="!isNewCalculator()"
          type="button"
          class="inline-flex items-center rounded-md mt-1 border border-transparent bg-red-600 px-3 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
          @click="remove"
        >
          <XMarkIcon class="-ml-1 mr-3 h-5 w-5" aria-hidden="true" />
          Remove
        </button>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRouter, useRoute } from "vue-router";
import { storeToRefs } from "pinia";
import { XMarkIcon } from "@heroicons/vue/24/outline";
import FormInput from "@/frontend/components/form/FormInput.vue";
import DateRangePicker from "@/frontend/components/form/DateRangePicker.vue";
import useCalculatorStore from "@/frontend/stores/Calculator";

const route = useRoute();
const store = useCalculatorStore();

const calculatorData = computed(
  () =>
    store.find(String(route.params.id)) ||
    store.newDefaultItem(String(route.params.id))
);

function saveCalculator(): void {
  store.save(calculatorData.value);
}

function saveDateRange(startDate: string | null, endDate: string | null): void {
  calculatorData.value.startDate = startDate || undefined;
  calculatorData.value.endDate = endDate || undefined;

  saveCalculator();
}

const { data: calculators } = storeToRefs(store);

function isNewCalculator(): boolean {
  return !store.find(calculatorData.value.id);
}

const router = useRouter();

const remove = () => {
  if (confirm("Are you sure?")) {
    store.remove(calculatorData.value.id);

    const firstCalculator = calculators.value[0];

    if (firstCalculator) {
      router.push({
        name: "calculator-item",
        params: { id: firstCalculator.id },
      });
    } else {
      router.push({
        name: "calculator",
      });
    }
  }
};
</script>

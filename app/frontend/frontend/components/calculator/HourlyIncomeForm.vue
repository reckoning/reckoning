<template>
  <div class="mt-5 w-full">
    <h2 class="text-lg font-medium leading-6 text-gray-900 pb-1">
      Hour Based Data
    </h2>
    <div class="flex flex-row space-x-4 border-t border-gray-200 pt-3">
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="hourRate"
          v-model="calculatorData.hourRate"
          type="number"
          label="Hour Rate"
          @input="saveCalculator"
        />
      </div>
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="daysOfWeek"
          v-model="calculatorData.daysOfWeek"
          type="number"
          label="Workdays per Week"
          @input="saveCalculator"
        />
        <FormInput
          id="hoursPerDay"
          v-model="calculatorData.hoursPerDay"
          type="number"
          label="Hours per Day"
          @input="saveCalculator"
        />
      </div>
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="absence"
          v-model="calculatorData.absence"
          type="number"
          label="Absence per Year"
          @input="saveCalculator"
        />
        <FormInput
          id="vacation"
          v-model="calculatorData.vacation"
          type="number"
          label="Vacation per Year"
          @input="saveCalculator"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router";
import FormInput from "@/frontend/components/form/FormInput.vue";
import useCalculatorStore from "@/frontend/stores/Calculator";

const route = useRoute();
const store = useCalculatorStore();

const calculatorData = computed(
  () =>
    store.find(String(route.params.id)) ||
    store.newDefaultItem(String(route.params.id))
);

function saveCalculator() {
  store.save(calculatorData.value);
}
</script>

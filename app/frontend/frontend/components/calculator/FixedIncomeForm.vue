<template>
  <div class="mt-5 w-full">
    <h2 class="text-lg font-medium leading-6 text-gray-900 pb-1">
      Fix Income Data
    </h2>
    <div class="flex flex-row space-x-4 border-t border-gray-200 pt-3">
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="baseIncome"
          v-model="calculatorData.baseIncome"
          type="number"
          label="Base Income"
          @input="saveCalculator"
        />
      </div>
      <div class="basis-1/3 space-y-3"></div>
      <div class="basis-1/3 space-y-3"></div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import FormInput from '@/frontend/components/form/FormInput.vue'
import useCalculatorStore from '@/frontend/stores/Calculator'

const route = useRoute()
const store = useCalculatorStore()

const calculatorData = computed(
  () =>
    store.find(String(route.params.uuid)) ||
    store.newDefaultItem(String(route.params.uuid))
)

function saveCalculator() {
  store.save(calculatorData.value)
}
</script>

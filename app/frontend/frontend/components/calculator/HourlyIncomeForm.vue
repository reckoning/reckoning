<template>
  <div class="mt-5 w-full">
    <h2 class="text-lg font-medium leading-6 text-gray-900 pb-1">
      Hour Based Data
    </h2>
    <div class="flex flex-row space-x-4 border-t border-gray-200 pt-3">
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="hourRate"
          type="number"
          label="Hour Rate"
          v-model="calculatorData.hourRate"
          @input="saveCalculator"
        />
      </div>
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="daysOfWeek"
          type="number"
          label="Workdays per Week"
          v-model="calculatorData.daysOfWeek"
          @input="saveCalculator"
        />
        <FormInput
          id="hoursPerDay"
          type="number"
          label="Hours per Day"
          v-model="calculatorData.hoursPerDay"
          @input="saveCalculator"
        />
      </div>
      <div class="basis-1/3 space-y-3">
        <FormInput
          id="absence"
          type="number"
          label="Absence per Year"
          v-model="calculatorData.absence"
          @input="saveCalculator"
        />
        <FormInput
          id="vacation"
          type="number"
          label="Vacation per Year"
          v-model="calculatorData.vacation"
          @input="saveCalculator"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import useCalculatorStore from '@/frontend/stores/Calculator'
import FormInput from '@/frontend/components/form/FormInput.vue'

const route = useRoute()
const store = useCalculatorStore()

const calculatorData = computed(() => {
  return (
    store.find(String(route.params.uuid)) ||
    store.newDefaultItem(String(route.params.uuid))
  )
})

function saveCalculator() {
  store.save(calculatorData.value)
}
</script>

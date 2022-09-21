<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8">
      <h1 class="text-2xl text-gray-900">Calculator</h1>

      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <router-link
            v-for="item in calculators"
            :key="item.uuid"
            :to="{ name: 'calculator-item', params: { uuid: item.uuid } }"
            :class="[
              item.uuid === route.params.uuid
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
              'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm',
            ]"
            :aria-current="item.uuid === route.params.uuid ? 'page' : undefined"
          >
            {{ item.name || item.uuid }}
          </router-link>
          <router-link
            key="new-calculator"
            :to="{ name: 'calculator' }"
            :class="[
              isNewCalculator()
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
              'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm',
            ]"
            :aria-current="isNewCalculator() ? 'page' : undefined"
          >
            <PlusIcon class="w-5 h-5" />
          </router-link>
        </nav>
      </div>

      <CalculatorBaseForm />

      <CalculatorFixedIncomeForm />

      <CalculatorHourlyIncomeForm />

      <div class="mt-5 border-t border-gray-200">
        <dl class="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
          <div
            v-for="item in stats"
            :key="item.name"
            class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6"
          >
            <dt class="truncate text-sm font-medium text-gray-500">
              {{ item.name }}
            </dt>
            <dd
              class="mt-1 text-3xl font-semibold tracking-tight text-gray-900"
            >
              {{ item.stat }}
            </dd>
          </div>
        </dl>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted } from 'vue'
import {
  format,
  isWeekend,
  startOfYear,
  endOfYear,
  eachDayOfInterval,
  differenceInMonths,
} from 'date-fns'
import { useRoute } from 'vue-router'
import { storeToRefs } from 'pinia'
import { PlusIcon } from '@heroicons/vue/24/outline'
import CalculatorFixedIncomeForm from '@/frontend/components/calculator/FixedIncomeForm.vue'
import CalculatorHourlyIncomeForm from '@/frontend/components/calculator/HourlyIncomeForm.vue'
import CalculatorBaseForm from '@/frontend/components/calculator/BaseForm.vue'
import useCalculatorStore from '@/frontend/stores/Calculator'
import apiClient from '@/frontend/api'
import type { GermanHoliday } from '@/frontend/api/client/models/GermanHoliday'

const holidayDates = computed(() =>
  holidays.value.map((holiday: any) => holiday.date)
)

const route = useRoute()
const store = useCalculatorStore()
const { data: calculators } = storeToRefs(store)

const currentYear = new Date(2022, 0, 1)

const calculatorData = computed(
  () =>
    store.find(String(route.params.uuid)) ||
    store.newDefaultItem(String(route.params.uuid))
)

function isNewCalculator() {
  return !store.find(calculatorData.value.uuid)
}

const daysOfWeek = computed(() => calculatorData.value.daysOfWeek || 0)
const baseIncome = computed(() => calculatorData.value.baseIncome || 0)
const hourRate = computed(() => calculatorData.value.hourRate || 0)
const hoursPerDay = computed(() => calculatorData.value.hoursPerDay || 0)
const vacation = computed(() => calculatorData.value.vacation || 0)
const absence = computed(() => calculatorData.value.absence || 0)

const remainingMonths: number = differenceInMonths(
  endOfYear(new Date()),
  new Date()
)

const holidays = ref<GermanHoliday[]>([])

onMounted(async () => {
  holidays.value = await apiClient.holidays.getGermanHolidays({
    year: currentYear.getFullYear(),
    state: ['HH', 'NATIONAL'],
  })
})

const normalizedVacation = computed(
  () => (vacation.value * daysOfWeek.value) / 5
)

const normalizedAbsence = computed(() => (absence.value * daysOfWeek.value) / 5)

const vacationPerMonth = computed(() => normalizedVacation.value / 12)

const absencePerMonth = computed(() => normalizedAbsence.value / 12)

const remainingVacationValue = computed(
  () => vacationPerMonth.value * remainingMonths
)

const remainingAbsenceValue = computed(
  () => absencePerMonth.value * remainingMonths
)

const remainingWorkDays = computed(() =>
  Math.round(
    ((remainingWeekDaysForYear.value.length -
      remainingVacationValue.value -
      remainingAbsenceValue.value) *
      daysOfWeek.value) /
      5
  )
)

const remainingWeekDaysForYear = computed(() => {
  const currentDay = new Date()
  const daysForYear = eachDayOfInterval({
    start: currentDay,
    end: endOfYear(currentDay),
  })

  return daysForYear.filter(
    (day) =>
      !isWeekend(day) && !holidayDates.value.includes(format(day, 'yyyy-MM-dd'))
  )
})

const workDays = computed(() =>
  Math.round(
    ((weekDaysForYear.value.length -
      normalizedVacation.value -
      normalizedAbsence.value) *
      daysOfWeek.value) /
      5
  )
)

const weekDaysForYear = computed(() => {
  const daysForYear: Date[] = eachDayOfInterval({
    start: startOfYear(currentYear),
    end: endOfYear(currentYear),
  })

  return daysForYear.filter(
    (day) =>
      !isWeekend(day) && !holidayDates.value.includes(format(day, 'yyyy-MM-dd'))
  )
})

const roundToTwo = (num: number) =>
  +`${Math.round(Number(`${String(num)}e+2`))}e-2`

const stats = computed(() => {
  const baseIncomePerMonth = baseIncome.value / 12.0
  const baseIncomeRemaining = baseIncomePerMonth * remainingMonths
  const ratePerDay = hourRate.value * hoursPerDay.value

  return [
    { name: 'Workdays per Year', stat: workDays },
    {
      name: 'Remaining Workdays',
      stat: roundToTwo(remainingWorkDays.value),
    },
    {
      name: 'Remaining Months',
      stat: roundToTwo(remainingMonths),
    },
    { name: 'Vacation per Month', stat: roundToTwo(vacationPerMonth.value) },
    { name: 'Absence per Month', stat: roundToTwo(absencePerMonth.value) },
    {
      name: 'Remaining Vacation',
      stat: roundToTwo(remainingVacationValue.value),
    },
    {
      name: 'Remaining Absence',
      stat: roundToTwo(remainingAbsenceValue.value),
    },
    { name: 'Rate per Day', stat: roundToTwo(ratePerDay) },
    {
      name: 'Possible Income for rest of the Year',
      stat: roundToTwo(
        baseIncomeRemaining + ratePerDay * remainingWorkDays.value
      ),
    },
    {
      name: 'Possible Monthly Income for rest of the Year',
      stat: roundToTwo(
        baseIncomePerMonth +
          (ratePerDay * remainingWorkDays.value) / remainingMonths
      ),
    },
    {
      name: 'Possible Income for a whole Year',
      stat: roundToTwo(baseIncome.value + ratePerDay * workDays.value),
    },
    {
      name: 'Possible Monthly Income for a whole Year',
      stat: roundToTwo(
        baseIncomePerMonth + (ratePerDay * workDays.value) / 12.0
      ),
    },
  ]
})
</script>

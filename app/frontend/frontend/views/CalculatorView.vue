<template>
  <div class="py-6">
    <div class="mx-auto px-4 sm:px-6 md:px-8">
      <h1 class="text-2xl text-gray-900">Calculator</h1>

      <div class="w-full max-w-xs">
        <div>
          <label for="hourRate" class="block text-sm font-medium text-gray-700">
            Hour Rate
          </label>
          <div class="mt-1">
            <input
              type="number"
              name="hourRate"
              id="hourRate"
              v-model="hourRate"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="you@example.com"
            />
          </div>
        </div>

        <div>
          <label
            for="hoursPerDay"
            class="block text-sm font-medium text-gray-700"
          >
            Hours per Day
          </label>
          <div class="mt-1">
            <input
              type="number"
              name="hoursPerDay"
              id="hoursPerDay"
              v-model="hoursPerDay"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
          </div>
        </div>
        <div>
          <label
            for="daysOfWeek"
            class="block text-sm font-medium text-gray-700"
          >
            Workdays per Week
          </label>
          <div class="mt-1">
            <input
              type="number"
              name="daysOfWeek"
              id="daysOfWeek"
              v-model="daysOfWeek"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
          </div>
        </div>
        <div>
          <label for="vacation" class="block text-sm font-medium text-gray-700">
            Vacation per Year
          </label>
          <div class="mt-1">
            <input
              type="number"
              name="vacation"
              id="vacation"
              v-model="vacation"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
          </div>
        </div>
        <div>
          <label for="absence" class="block text-sm font-medium text-gray-700">
            Absence per Year
          </label>
          <div class="mt-1">
            <input
              type="number"
              name="absence"
              id="absence"
              v-model="absence"
              class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
          </div>
        </div>
      </div>

      <div>
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
  addDays,
} from 'date-fns'

export type HolidayResponse = {
  [state: string]: {
    [holidayName: string]: {
      datum: string
      info: string
    }
  }
}
export type Holiday = {
  state: string
  name: string
  date: string
}

const fetchHolidays = async (): Promise<HolidayResponse> => {
  const response = await fetch('https://feiertage-api.de/api/')
  return response.json()
}

const normalizedHolidays = computed(() => {
  return Object.keys(holidays.value)
    .map((key: string) => {
      return Object.keys(holidays.value[key]).map((holidayName: string) => {
        return {
          state: key,
          name: holidayName,
          date: holidays.value[key][holidayName].datum,
        }
      })
    })
    .flat()
})

const holidayDates = computed(() => {
  return normalizedHolidays.value
    .filter(
      (holiday: any) => holiday.state === 'HH' || holiday.state === 'NATIONAL'
    )
    .map((holiday: any) => holiday.date)
})

const hourRate = ref<number>(0)
const hoursPerDay = ref<number>(8)
const daysOfWeek = ref<number>(5)
const vacation = ref<number>(30)
const absence = ref<number>(10)
const remainingMonths: number = differenceInMonths(
  endOfYear(new Date()),
  new Date()
)

const ratePerDay = computed(() => {
  return hourRate.value * hoursPerDay.value
})

const holidays = ref<HolidayResponse>({})

onMounted(async () => {
  holidays.value = await fetchHolidays()
})

const normalizedVacation = computed(() => {
  return (vacation.value * daysOfWeek.value) / 5
})

const normalizedAbsence = computed(() => {
  return (absence.value * daysOfWeek.value) / 5
})

const vacationPerMonth = computed(() => {
  return normalizedVacation.value / 12
})

const absencePerMonth = computed(() => {
  return normalizedAbsence.value / 12
})

const remainingVacationValue = computed(() => {
  return vacationPerMonth.value * remainingMonths
})

const remainingAbsenceValue = computed(() => {
  return absencePerMonth.value * remainingMonths
})

const remainingWorkDays = computed(() => {
  return Math.round(
    ((remainingWeekDaysForYear.value.length -
      remainingVacationValue.value -
      remainingAbsenceValue.value) *
      daysOfWeek.value) /
      5
  )
})

const remainingWeekDaysForYear = computed(() => {
  const daysForYear = eachDayOfInterval({
    start: new Date(),
    end: endOfYear(new Date()),
  })

  return daysForYear.filter((day) => {
    return (
      !isWeekend(day) && !holidayDates.value.includes(format(day, 'yyyy-MM-dd'))
    )
  })
})

const workDays = computed(() => {
  return Math.round(
    ((weekDaysForYear.value.length -
      normalizedVacation.value -
      normalizedAbsence.value) *
      daysOfWeek.value) /
      5
  )
})

const weekDaysForYear = computed(() => {
  const daysForYear: Date[] = eachDayOfInterval({
    start: startOfYear(new Date()),
    end: endOfYear(new Date()),
  })

  return daysForYear.filter((day) => {
    return (
      !isWeekend(day) && !holidayDates.value.includes(format(day, 'yyyy-MM-dd'))
    )
  })
})

const roundToTwo = (num: number) => {
  return +(Math.round(Number(String(num) + 'e+2')) + 'e-2')
}

const stats = computed(() => [
  { name: 'Workdays for Current Year', stat: workDays },
  {
    name: 'Remaining Workdays for Current Year',
    stat: roundToTwo(remainingWorkDays.value),
  },
  {
    name: 'Remaining Months for Current Year',
    stat: roundToTwo(remainingMonths),
  },
  { name: 'Vacation per Month', stat: roundToTwo(vacationPerMonth.value) },
  { name: 'Absence per Month', stat: roundToTwo(absencePerMonth.value) },
  {
    name: 'Remaining Vacation',
    stat: roundToTwo(remainingVacationValue.value),
  },
  { name: 'Remaining Absence', stat: roundToTwo(remainingAbsenceValue.value) },
  { name: 'Rate per Day', stat: roundToTwo(ratePerDay.value) },
  {
    name: 'Possible Income for rest of the Year',
    stat: roundToTwo(ratePerDay.value * remainingWorkDays.value),
  },
  {
    name: 'Possible Monthly Income for rest of the Year',
    stat: roundToTwo(
      (ratePerDay.value * remainingWorkDays.value) / remainingMonths
    ),
  },
  {
    name: 'Possible Income for a whole Year',
    stat: roundToTwo(ratePerDay.value * workDays.value),
  },
  {
    name: 'Possible Monthly Income for a whole Year',
    stat: roundToTwo((ratePerDay.value * workDays.value) / 12.0),
  },
])
</script>

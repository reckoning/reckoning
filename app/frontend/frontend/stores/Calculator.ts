import { ref } from 'vue'
import { defineStore } from 'pinia'

export type CalculatorData = {
  uuid: string
  name: string | null
  baseIncome: number | null
  hourRate: number | null
  hoursPerDay: number | null
  daysOfWeek: number | null
  vacation: number | null
  absence: number | null
}

export default defineStore(
  'Calculator',
  () => {
    const data = ref<CalculatorData[]>([])

    function newDefaultItem(uuid: string): CalculatorData {
      return {
        uuid,
        name: 'New',
        baseIncome: 0,
        hourRate: 0,
        hoursPerDay: 8,
        daysOfWeek: 5,
        vacation: 30,
        absence: 10,
      }
    }

    function save(dataItem: CalculatorData): CalculatorData {
      const index = data.value.findIndex((item) => item.uuid === dataItem.uuid)

      if (index === -1) {
        data.value.push(dataItem)
      } else {
        data.value[index] = dataItem
      }

      return dataItem
    }

    function remove(uuid: string): boolean {
      const index = data.value.findIndex((item) => item.uuid === uuid)

      if (index === -1) {
        return false
      }
      data.value.splice(index, 1)
      return true
    }

    function find(uuid: string): CalculatorData | null {
      const existingData = data.value.find((item) => item.uuid === uuid)

      if (existingData) {
        return existingData
      }

      return null
    }

    function findOrCreate(uuid: string) {
      const existingData = data.value.find((item) => item.uuid === uuid)

      if (existingData) {
        return existingData
      }

      return save(newDefaultItem(uuid))
    }

    return { data, newDefaultItem, save, remove, find, findOrCreate }
  },
  {
    persist: true,
  }
)

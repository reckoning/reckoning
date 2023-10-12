import { ref } from "vue";
import { defineStore } from "pinia";
import { format, endOfYear } from "date-fns";

export type CalculatorData = {
  id: string;
  name: string | null;
  baseIncome: number | null;
  hourRate: number | null;
  hoursPerDay: number | null;
  daysOfWeek: number | null;
  vacation: number | null;
  absence: number | null;
  startDate?: string;
  endDate?: string;
};

export default defineStore(
  "Calculator",
  () => {
    const data = ref<CalculatorData[]>([]);

    function newDefaultItem(id: string): CalculatorData {
      return {
        id,
        name: "New",
        baseIncome: 0,
        hourRate: 0,
        hoursPerDay: 8,
        daysOfWeek: 5,
        vacation: 30,
        absence: 10,
        startDate: format(new Date(), "yyyy-MM-dd"),
        endDate: format(endOfYear(new Date()), "yyyy-MM-dd"),
      };
    }

    function save(dataItem: CalculatorData): CalculatorData {
      const index = data.value.findIndex((item) => item.id === dataItem.id);

      if (index === -1) {
        data.value.push(dataItem);
      } else {
        data.value[index] = dataItem;
      }

      return dataItem;
    }

    function remove(id: string): boolean {
      const index = data.value.findIndex((item) => item.id === id);

      if (index === -1) {
        return false;
      }
      data.value.splice(index, 1);
      return true;
    }

    function find(id: string): CalculatorData | null {
      const existingData = data.value.find((item) => item.id === id);

      if (existingData) {
        return existingData;
      }

      return null;
    }

    function findOrCreate(id: string) {
      const existingData = data.value.find((item) => item.id === id);

      if (existingData) {
        return existingData;
      }

      return save(newDefaultItem(id));
    }

    return { data, newDefaultItem, save, remove, find, findOrCreate };
  },
  {
    persist: true,
  }
);

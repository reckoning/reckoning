import { defineStore } from "pinia";
import { ref } from "vue";

export type ToastLevel = "success" | "info" | "error";

export interface Toast {
  id: number;
  level: ToastLevel;
  message: string;
}

export const useToastsStore = defineStore("toasts", () => {
  const toasts = ref<Toast[]>([]);

  let nextId = 0;

  function push(level: ToastLevel, message: string): number {
    const id = nextId++;
    toasts.value.push({ id, level, message });
    return id;
  }

  function dismiss(id: number): void {
    toasts.value = toasts.value.filter((toast) => toast.id !== id);
  }

  function clear(): void {
    toasts.value = [];
  }

  return { toasts, push, dismiss, clear };
});

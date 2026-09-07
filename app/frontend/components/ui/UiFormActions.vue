<script setup lang="ts">
import UiButton from "./UiButton.vue"

// `shared/forms/_submit`: a rule, then a large primary save beside a plain
// cancel.
defineProps<{saveLabel: string; cancelLabel: string; busy?: boolean}>()

const emit = defineEmits<{cancel: []}>()
</script>

<template>
  <div>
    <hr class="my-5 border-t border-rule" />

    <div class="flex flex-wrap gap-2 max-md:flex-col">
      <UiButton variant="primary" size="large" type="submit" :disabled="busy" data-test="submit">
        {{ saveLabel }}
      </UiButton>

      <UiButton type="button" data-test="cancel" @click="emit('cancel')">
        {{ cancelLabel }}
      </UiButton>
    </div>
  </div>
</template>

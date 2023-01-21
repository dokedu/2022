<template>
  <label class="flex gap-3 whitespace-nowrap text-sm font-medium text-slate-900">
    <input
      v-model="model"
      class="my-1 h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
      type="checkbox"
    />
    <slot />
  </label>
</template>

<script lang="ts">
import { computed, ref } from 'vue'

export default {
  props: {
    modelValue: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:modelValue', 'change'],
  setup(props: any, { emit }: any) {
    const model = computed({
      get: () => props.modelValue,
      set: (value) => {
        emit('update:modelValue', value)
        emit('change', value)
      },
    })

    return {
      model,
    }
  },
}
</script>

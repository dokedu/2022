<template>
  <label class="flex items-center text-sm font-medium text-gray-700">
    <button :class="[
      model ? 'bg-blue-600' : 'bg-gray-200',
      'relative mr-3 inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-100 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
    ]" @click="model = !model">
      <span class="sr-only">Use setting</span>
      <span aria-hidden="true" :class="[
        model ? 'translate-x-5' : 'translate-x-0',
        'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-100 ease-in-out',
      ]" />
    </button>
    <slot></slot>
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
  emits: ['update:modelValue'],
  setup(props: any, { emit }: any) {
    const enabled = ref(props.modelValue)
    const model = computed({
      get: () => enabled.value,
      set: (value) => {
        enabled.value = value
        emit('update:modelValue', value)
      },
    })

    return {
      model,
    }
  },
}
</script>

<template>
  <span
    class="inline-flex items-center rounded-full bg-blue-100 py-0.5 pl-2.5 text-sm font-medium text-blue-700"
    :class="[removable ? 'pr-1' : 'pr-2.5']"
  >
    <span class="max-w-[500px] line-clamp-1">
      <slot></slot>
    </span>
    <button
      v-if="removable"
      type="button"
      class="ml-0.5 inline-flex h-4 w-4 flex-shrink-0 items-center justify-center rounded-full text-blue-400 hover:bg-blue-200 hover:text-blue-500 focus:bg-blue-500 focus:text-white focus:outline-none"
      @click="remove"
    >
      <span class="sr-only">Entfernen</span>
      <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
        <path stroke-linecap="round" stroke-width="1.5" d="M1 1l6 6m0-6L1 7" />
      </svg>
    </button>
  </span>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'DTag',
  props: {
    removable: {
      type: Boolean,
      default: false,
    },
    data: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['remove'],
  setup(props, { emit }) {
    const remove = () => {
      emit('remove', props.data)
    }

    return {
      remove,
    }
  },
})
</script>

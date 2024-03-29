<template>
  <div class="flex flex-col">
    <label v-if="$props.label" class="mb-1 block text-sm font-medium text-gray-700">{{ $props.label }}</label>
    <div class="relative">
      <input v-model="model"
        class="relative w-full cursor-default rounded-md border-none bg-gray-100 py-2.5 pl-3 text-left align-middle text-gray-700 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 sm:text-sm"
        :type="$props.type" :name="$props.name" :placeholder="$props.placeholder" :disabled="$props.disabled"
        :required="$props.required" v-bind="$attrs" />
    </div>
    <small v-if="errorMessage" class="mt-1 text-red-400">{{ errorMessage }}</small>

    <slot></slot>
  </div>
</template>

<script lang="ts">
import { defineComponent, toRef, watch } from 'vue'
import { useField } from 'vee-validate'

export default defineComponent({
  props: {
    modelValue: {
      type: [String, Number],
      default: '',
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'text',
    },
    name: {
      type: String,
      default: '',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    required: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    const name = toRef(props, 'name')

    const { value: model, errorMessage } = useField(name, undefined, {
      initialValue: toRef(props, 'modelValue'),
      validateOnMount: false,
    })

    watch(model, (value) => {
      emit('update:modelValue', value)
    })

    return {
      model,
      errorMessage,
    }
  },
})
</script>

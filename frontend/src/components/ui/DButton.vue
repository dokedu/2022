<template>
  <component :is="component"
    class="inline-block flex min-w-fit cursor-pointer select-none items-center justify-center rounded-lg align-middle focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
    :class="classes" :to="to">
    <slot />
  </component>
</template>

<script lang="ts">
import { computed, PropType, Ref, ref } from 'vue'

type ButtonSize = '28' | '36' | '42'
type ButtonType = 'drop' | 'icon' | 'text'
type ButtonStyle = 'danger' | 'danger-light' | 'primary' | 'secondary' | 'success' | 'link'

export default {
  props: {
    to: {
      type: Object,
      default: null,
    },
    size: {
      type: String as PropType<ButtonSize>,
      default: '36',
    },
    type: {
      type: String as PropType<ButtonType>,
      default: 'text',
    },
    // style
    look: {
      type: String as PropType<ButtonStyle>,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  setup(props: any) {
    const component = props.to?.name ? 'router-link' : 'button'

    const classes = computed(() => {
      let properties = ''

      switch (props.size) {
        case '28':
          properties += 'block px-2 py-1 min-h-[32px] '
          break
        default:
          properties += 'block px-3 py-2 min-h-[42px] '
          break
      }

      if (props.disabled) {
        properties += 'text-white bg-gray-100 text-gray-400 cursor-not-allowed'
        return properties
      }

      switch (props.look) {
        case 'primary':
          properties += 'text-white bg-blue-600 hover:bg-blue-700'
          break
        case 'danger':
          properties += 'text-white bg-red-500 hover:bg-red-600'
          break
        case 'danger-light':
          properties += 'text-red-700 bg-red-50 hover:bg-red-100'
          break
        case 'link':
          properties += 'bg-transparent hover:bg-gray-100'
          break
        default:
          properties += 'bg-gray-100 hover:bg-gray-200'
          break
      }
      return properties
    })

    return {
      props,
      component,
      classes,
    }
  },
}
</script>

<script lang="ts">
import * as feather from 'feather-icons'
import { h, computed } from 'vue'

export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    size: {
      type: String,
      default: '24',
    },
    color: {
      type: String,
      default: 'slate',
    },
  },
  setup(props) {
    const icon = computed(() => (props.name ? props.name : 'box'))
    const size = computed(() => (props.size ? props.size : '24'))
    const color = computed(() => (props.color ? props.color : 'slate'))

    return () =>
      h('div', {
        innerHTML: feather.icons[icon.value].toSvg({
          class: `stroke-${color.value}-900 w-[${size.value}px] h-[${size.value}px]`,
        }),
      })
  },
}
</script>

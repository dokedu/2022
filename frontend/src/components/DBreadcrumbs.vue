<template>
  <div class="flex select-none flex-col flex-wrap items-baseline sm:flex-row" data-cy="breadcrumbs">
    <div v-for="item in items()" :key="item.name" class="flex">
      <div class="text-slate-200">/</div>
      <component
        :is="item?.to ? 'router-link' : 'div'"
        :to="parseTo(item.to)"
        class="mx-1 mb-1 rounded-lg px-1 text-slate-700"
        :class="{
          'hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1': item.to,
        }"
      >
        {{ parseName(item.name) }}
      </component>
    </div>
  </div>
</template>

<script lang="ts">
import { RouterLinkProps, useRoute } from 'vue-router'
import { PropType } from 'vue'

interface Breadcrumb {
  name: string
  to?: RouterLinkProps
}

export default {
  name: 'DBreadcrumbs',
  props: {
    items: {
      type: Function as PropType<() => Breadcrumb>,
      required: true,
    },
  },
  setup() {
    const route = useRoute()

    const parseTo = (to: any) => {
      return { name: to?.name, params: to?.params }
    }

    const parseName = (name: string) => {
      if (name === ':id') {
        return route.params.id
      }

      return name
    }

    return {
      parseTo,
      parseName,
    }
  },
}
</script>

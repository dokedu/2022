<template>
  <div class="flex h-full flex-col print:h-auto">
    <DHeader />
    <div class="h-full overflow-auto py-4 px-2 print:h-auto print:p-0">
      <div class="print:max-h-none mx-auto max-h-full max-w-screen-lg py-4 print:h-auto print:max-w-none print:p-0">
        <div class="mb-4 flex justify-between print:hidden">
          <DBreadcrumbs :items="() => route && route.meta?.breadcrumbs" />
        </div>
        <router-view />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import DHeader from '../components/DHeader.vue'
import DBreadcrumbs from '../components/DBreadcrumbs.vue'
import DButton from '../components/ui/DButton.vue'
import { useRoute } from 'vue-router'

const route = useRoute()
</script>

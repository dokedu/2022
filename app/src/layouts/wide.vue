<template>
  <div class="flex h-full flex-col">
    <DHeader />
    <div class="h-full overflow-auto py-4">
      <div class="mx-auto h-full max-w-screen-2xl">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import DHeader from '../components/DHeader.vue'
import { useRoute } from 'vue-router'

const route = useRoute()
</script>

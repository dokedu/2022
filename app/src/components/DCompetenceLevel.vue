<template>
  <div
    class="rounded-lg p-1"
    :class="{ 'cursor-pointer hover:bg-slate-100': editable === true }"
    :title="`Stufe ${level}`"
  >
    <div class="flex h-[16px] w-[20px] items-end space-x-1">
      <div class="flex h-full w-[4px] items-end">
        <div v-if="level >= 1" class="h-[5px] w-full rounded-lg bg-blue-600"></div>
        <div v-else class="h-[5px] w-full rounded-lg bg-slate-300"></div>
      </div>
      <div class="flex h-full w-[4px] items-end">
        <div v-if="level >= 2" class="h-[10px] w-full rounded-lg bg-blue-600"></div>
        <div v-else class="h-[10px] w-full rounded-lg bg-slate-300"></div>
      </div>
      <div class="flex h-full w-[4px] items-end">
        <div v-if="level >= 3" class="h-[16px] w-full rounded-lg bg-blue-600"></div>
        <div v-else class="h-[16px] w-full rounded-lg bg-slate-300"></div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { defineProps, toRefs } from 'vue'

const props = defineProps({
  level: {
    type: Number,
    default: 1,
  },
  editable: {
    type: Boolean,
    default: false,
  },
})

const { level, editable } = toRefs(props)
</script>

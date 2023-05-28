<template>
  <div class="flex-inline w-fit rounded-md px-1 text-sm" :class="parseStatusColor(status.status)" data-cy="name">
    {{ parseStatus(status.status) }}
  </div>
</template>

<script lang="ts" setup>
import { defineProps } from 'vue'

const status = defineProps({ status: { type: String, required: true } })

const parseStatus = (status: string) => {
  switch (status) {
    case 'pending':
      return 'In Bearbeitung'
    case 'done':
      return 'Fertig'
    case 'error':
      return 'Fehler'
  }
}

const parseStatusColor = (status: string) => {
  switch (status) {
    case 'pending':
      return 'bg-orange-100 text-orange-900'
    case 'done':
      return 'bg-green-100 text-green-900'
    case 'error':
      return 'bg-red-100 text-red-900'
  }
}
</script>

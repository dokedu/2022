<template>
  <DEntryForm />
</template>

<script lang="ts">
import DEntryForm from '../../../components/d-entry/DEntryForm.vue'
import { useEntryStore } from '../../../store/entry'

export default {
  components: {
    DEntryForm,
  },
  setup() {
    const entryStore = useEntryStore()

    entryStore.$reset()
    return {}
  },
}
</script>

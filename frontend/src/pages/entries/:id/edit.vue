<template>
  <DEntryForm :id="id" />
</template>

<script lang="ts">
import DEntryForm from '../../../components/entries/DEntryForm.vue'
import { useRoute } from 'vue-router'

export default {
  components: {
    DEntryForm,
  },
  setup() {
    const route = useRoute()

    return {
      id: route.params.id,
    }
  },
}
</script>

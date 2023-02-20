<script lang="ts" setup>
import DefaultLayout from './layouts/DefaultLayout.vue'
import LoginLayout from './layouts/LoginLayout.vue'
import WideLayout from './layouts/WideLayout.vue'
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import supabase from './api/supabase'

const route = useRoute()
const router = useRouter()

supabase.auth.onAuthStateChange(async (event, session) => {
  console.log(event)
  switch (event) {
    case 'SIGNED_IN':
      if (!session?.access_token) return false
      if (!session?.refresh_token) return false
      console.log('SIGNED_IN::SESSION', session)
      await supabase.auth.setSession({ access_token: session?.access_token, refresh_token: session?.refresh_token })
      break
    case 'SIGNED_OUT':
      await router.push({ name: 'logout' })
      break
  }
})

const CurrentLayout = computed(() => {
  switch (route.meta.layout) {
    case 'Default':
      return DefaultLayout
    case 'Login':
      return LoginLayout
    case 'Wide':
      return WideLayout
    default:
      return DefaultLayout
  }
})
</script>

<template>
  <component :is="CurrentLayout" class="text-slate-900"></component>
</template>

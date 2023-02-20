<script lang="ts" setup>
import DefaultLayout from './layouts/DefaultLayout.vue'
import LoginLayout from './layouts/LoginLayout.vue'
import WideLayout from './layouts/WideLayout.vue'
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import supabase from './api/supabase'
import { useStore } from './store/store'
import { useCompetenceStore } from './store/competence'

const route = useRoute()
const router = useRouter()

supabase.auth.onAuthStateChange(async (event, session) => {
  console.log(event)
  switch (event) {
    case 'SIGNED_IN':
      console.log('ACCESS_TOKEN', session?.access_token)
      console.log('REFRESH_TOKEN', session?.refresh_token)
      //if (!session?.access_token) break
      //if (!session?.refresh_token) break
      //await supabase.auth.setSession({ access_token: session?.access_token, refresh_token: session?.refresh_token })
      break
    case 'SIGNED_OUT':
      useStore().$reset()
      useCompetenceStore().$reset()
      localStorage.clear()
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

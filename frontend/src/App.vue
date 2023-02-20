<script lang="ts" setup>
import DefaultLayout from './layouts/DefaultLayout.vue'
import LoginLayout from './layouts/LoginLayout.vue'
import WideLayout from './layouts/WideLayout.vue'
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import supabase from './api/supabase'

const route = useRoute()
const router = useRouter()

supabase.auth.onAuthStateChange(async (event) => {
  console.log(event)
  switch (event) {
    case 'SIGNED_OUT':
      await router.push({ name: 'logout' })
      break
    case 'PASSWORD_RECOVERY':
      const access_token = route.query.access_token
      const type = route.query.type
      await router.push({ name: 'password-reset', query: { access_token, type } })
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

<script lang="ts" setup>
import DefaultLayout from './layouts/DefaultLayout.vue'
import LoginLayout from './layouts/LoginLayout.vue'
import WideLayout from './layouts/WideLayout.vue'
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useStore } from './store/store'
import supabase from './api/supabase'
import { redirectAfterLogin } from './router/_index'

const route = useRoute()
const router = useRouter()

supabase.auth.onAuthStateChange(async (event, payload) => {
  console.log(event)
  switch (event) {
    case 'SIGNED_IN':
      await useStore().afterLogin(payload)

      // TODO: this might not be the most elegant solution, but it works for now
      if (route.name === 'login') {
        await router.push(redirectAfterLogin)
      }

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

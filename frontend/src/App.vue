<script lang="ts">
import DefaultLayout from './layouts/DefaultLayout.vue'
import LoginLayout from './layouts/LoginLayout.vue'
import WideLayout from './layouts/WideLayout.vue'
import { computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useStore } from './store/store'
import supabase from './api/supabase'
import { redirectAfterLogin } from './router/_index'
import { useCompetenceStore } from './store/competence'

export default {
  components: {
    DefaultLayout,
    LoginLayout,
    WideLayout,
  },
  setup() {
    const store = useStore()
    const competenceStore = useCompetenceStore()
    const route = useRoute()
    const router = useRouter()

    const layoutName = computed(() => (route.meta.layout ? route.meta.layout : 'Default'))
    const currentLayout = computed(() => `${layoutName.value}Layout`)

    // TODO: refactor this and make it more generic
    watch(
      store.$state,
      (state) => {
        // persist the whole state to the local storage whenever it changes
        localStorage.setItem('pinia.state', JSON.stringify(state))
      },
      { deep: true },
    )
    watch(
      competenceStore.$state,
      (state) => {
        // persist the whole state to the local storage whenever it changes
        localStorage.setItem('pinia.state.competence', JSON.stringify(state))
      },
      { deep: true },
    )

    // load the state from the local storage
    onMounted(() => {
      const refState = JSON.parse(localStorage.getItem('pinia.state'))
      store.$state = refState
      const refCompetenceState = JSON.parse(localStorage.getItem('pinia.state.competence'))
      competenceStore.$state = refCompetenceState
    })

    supabase.auth.onAuthStateChange(async (event, payload) => {
      console.log(event)
      switch (event) {
        case 'SIGNED_IN':
          await store.afterLogin(payload)

          // todo: this might not be the most elegant solution, but it works for now
          if (route.name === 'login') {
            await router.push(redirectAfterLogin)
          }

          break
      }
    })

    return {
      currentLayout,
    }
  },
}
</script>

<template>
  <component :is="currentLayout" class="text-slate-900"></component>
</template>

<template>
  <div class="flex min-h-screen flex-col justify-center bg-gray-50 py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="mx-auto mb-2">
        <img src="/assets/dokedu-logo.svg" alt="Dokedu logo" class="mx-auto object-cover" height="75" width="112" />
      </div>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="rounded-lg bg-white py-8 px-4 shadow sm:px-10">
        <form class="space-y-6" @submit.prevent="login">
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700">E-Mail Adresse</label>
            <div class="mt-1">
              <input id="email" v-model="email" name="email" type="email" autocomplete="email" required
                placeholder="Deine E-Mail Adresse"
                class="block w-full appearance-none rounded-lg border border-gray-200 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm" />
            </div>
          </div>

          <div>
            <label for="password" class="block text-sm font-medium text-gray-700">Passwort</label>
            <div class="mt-1">
              <input id="password" v-model="password" name="password" type="password" autocomplete="current-password"
                required placeholder="Dein Passwort"
                class="block w-full appearance-none rounded-lg border border-gray-200 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm" />
            </div>
          </div>

          <div>
            <button data-cy="submit" type="submit"
              class="flex w-full justify-center rounded-lg border border-transparent bg-blue-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
              Anmelden
            </button>
          </div>
          <div class="flex items-center justify-between">
            <div class="m-auto items-center text-sm">
              <router-link :to="{ name: 'forgot-password' }"
                class="font-medium text-blue-600 hover:text-blue-500">Passwort vergessen?</router-link>
            </div>
          </div>
          <div v-show="errorMsg && errorMsg?.length > 0" data-cy="errorMsg" class="text-sm font-medium text-red-500">
            {{ errorMsg }}
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { ref } from 'vue'
import supabase from '../../api/supabase'
import { useStore } from '../../store/store'

export default {
  name: 'PageLogin',
  setup() {
    const email = ref('')
    const password = ref('')
    const errorMsg = ref(null as null | string)
    const store = useStore()

    const login = async () => {
      const res = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
      })

      if (res.error) {
        if (res.error.message === 'Invalid login credentials') {
          errorMsg.value = 'E-Mail oder Passwort falsch'
        } else {
          errorMsg.value = 'Unbekannter Fehler'
        }

        return
      }

      await store.afterLogin(res.data)
    }

    return {
      email,
      password,
      errorMsg,
      login,
    }
  },
}
</script>

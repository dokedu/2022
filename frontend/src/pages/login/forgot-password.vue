<template>
  <div class="flex min-h-screen flex-col justify-center bg-slate-50 py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="mx-auto mb-2">
        <img src="/assets/dokedu-logo.svg" height="75" width="112" alt="Dokedu logo" class="mx-auto" />
      </div>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="rounded-lg bg-white py-8 px-4 shadow sm:px-10">
        <form v-if="!success" class="space-y-6" @submit.prevent="login">
          <div>
            <router-link class="mb-2 block font-medium text-blue-600 hover:text-blue-500" :to="{ name: 'login' }">
              Zurück zur Anmeldung
            </router-link>
            <h2 class="text-md mb-2 font-semibold text-slate-900">Passwort zurücksetzen</h2>
            <p class="text-slate-700">
              Wir senden dir dann eine E-Mail mit einem Link, über den du dein Passwort zurücksetzen kannst.
            </p>
          </div>
          <div>
            <label for="email" class="block text-sm font-medium text-slate-700">E-Mail Adresse</label>
            <div class="mt-1">
              <input id="email" v-model="email" name="email" type="email" autocomplete="email"
                placeholder="Gib deine E-Mail Adresse ein"
                class="block w-full appearance-none rounded-lg border border-slate-200 px-3 py-2 placeholder-slate-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm" />
            </div>
          </div>

          <div>
            <button data-cy="submit" type="submit"
              class="flex w-full justify-center rounded-lg border border-transparent bg-blue-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
              Passwort zurücksetzen
            </button>
          </div>
          <div data-cy="errorMsg" class="text-sm font-medium text-red-500">
            {{ errorMsg }}
          </div>
        </form>
        <div v-else>
          <h2 class="mb-2 text-xl font-medium text-slate-900">Bitte überprüfen deine Emails</h2>
          <p class="mb-8 text-slate-700">
            Wir haben dir einen Link geschickt, um dein Passwort zurückzusetzen. Bitte folgen den Anweisungen in der
            E-Mail.
          </p>
          <DButton look="secondary" :to="{ name: 'login' }">Zurück zur Anmeldeseite</DButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref } from 'vue'
import supabase from '../../api/supabase'
import DButton from '../../components/ui/DButton.vue'

const RedirectTo = (import.meta.env.VITE_FRONTEND_URL || 'http://localhost:3001') + '/reset-password'

const email = ref('')
const errorMsg = ref(null as null | string)
const success = ref(false)

const login = async () => {
  success.value = false
  errorMsg.value = ''
  const res = await supabase.auth.resetPasswordForEmail(email.value, { redirectTo: RedirectTo })

  if (res.error) {
    errorMsg.value = res.error.message
    return
  }

  success.value = true
}
</script>

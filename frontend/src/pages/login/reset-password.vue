<template>
  <div class="flex min-h-screen flex-col justify-center bg-gray-50 py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="mx-auto mb-2">
        <img src="/assets/dokedu-logo.svg" height="75" width="112" alt="Dokedu logo" class="mx-auto" />
      </div>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="rounded-lg bg-white py-8 px-4 shadow sm:px-10">
        <form class="space-y-6" @submit.prevent="updateUser">
          <div>
            <h2 class="text-md mb-2 font-semibold text-gray-900">Neues Passwort festlegen</h2>
          </div>
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700">Passwort</label>
            <div class="mt-1">
              <input id="password" v-model="password" name="password" type="password" autocomplete="false" required
                placeholder="Gib dein neues Passwort ein"
                class="block w-full appearance-none rounded-lg border border-gray-200 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-blue-500 sm:text-sm" />
            </div>
          </div>

          <div>
            <button data-cy="submit" type="submit"
              class="flex w-full justify-center rounded-lg border border-transparent bg-blue-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
              Passwort speichern
            </button>
          </div>
          <div v-show="errorMsg && errorMsg.length > 1" data-cy="errorMsg" class="text-sm font-medium text-red-500">
            {{ errorMsg }} <br>
            <span class="text-xs">Bitte gib diesen Fehlercode bei deiner Supportanfrage mit an</span>
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
  name: 'PageResetPassword',
  setup() {
    const password = ref('')
    const errorMsg = ref(null as null | string)

    const updateUser = async () => {
      const session = await supabase.auth.getSession()
      const res = await supabase.auth.updateUser({ password: password.value })

      if (res.error) {
        errorMsg.value = res.error.message
        return
      }

      await useStore().afterLogin(session.data.session)
    }

    return {
      password,
      errorMsg,
      updateUser,
    }
  },
}
</script>

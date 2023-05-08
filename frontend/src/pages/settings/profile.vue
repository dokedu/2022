<template>
    <div>
        <h1 class="mb-5 text-3xl font-semibold text-neutral-900">Profile</h1>
        <form class="flex text-neutral-700 flex-col gap-4 max-w-md" @submit.prevent="handleSubmit">
            <p class="text-neutral-500">Bitte gib dein neues Passwort ein.</p>
            <input class="rounded-md border border-neutral-300" v-model="password" type="password" name="password"
                id="password" placeholder="Dein neues Passwort">
            <input class="rounded-md border border-neutral-300" v-model="passwordConfirm" type="password"
                name="password-confirm" id="password-confirm" placeholder="Bestätige dein neues Passwort">
            <button class=" bg-blue-100 text-blue-900 py-2 px-3 rounded-md hover:bg-blue-200" type="submit">
                Passwort ändern
            </button>
        </form>
    </div>
</template>

<script lang="ts" setup>
import { ref } from "vue"
import supabase from '../../api/supabase'

const password = ref('')
const passwordConfirm = ref('')


async function handleSubmit() {
    if (password.value.length < 8) {
        alert('Password must be at least 8 characters!');
        return;
    }

    if (password.value !== passwordConfirm.value) {
        alert('Passwords do not match!');
        return;
    }

    const { error } = await supabase.auth.updateUser({ password: password.value })

    if (error) {
        alert(error.message)
        return;
    }

    password.value = ""
    passwordConfirm.value = ""

    alert('Password updated successfully!')
}

</script>
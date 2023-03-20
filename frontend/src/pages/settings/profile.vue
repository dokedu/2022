<template>
    <div>
        <h1>Profile</h1>
        <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
            <p>Please enter your new password.</p>
            <input v-model="password" type="password" name="password" id="password" placeholder="Your new password">
            <input v-model="passwordConfirm" type="password" name="password-confirm" id="password-confirm"
                placeholder="Confirm your new password">
            <button type="submit">Save</button>
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
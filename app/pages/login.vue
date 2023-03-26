<template>
    <div>
        <h1>Login</h1>
        <form @submit.prevent="login">
            <input type="text" v-model="username" placeholder="Username">
            <input type="password" v-model="password" placeholder="Password">
            <button type="submit" class="bg-blue-500">Login</button>
        </form>
    </div>
</template>

<script lang="ts" setup>
import { ref } from 'vue'

const username = ref('')
const password = ref('')

function login() {
    console.log(username.value, password.value)
}
</script>
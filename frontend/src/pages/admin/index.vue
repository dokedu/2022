<template>
  <div class="mt-5 flex">
    <header class="min-w-fit border-r pr-4 pt-0">
      <div class="mb-3 text-sm uppercase text-slate-500">Einstellungen</div>
      <div class="flex flex-col gap-1">
        <router-link v-for="link in links" :key="link.name" :to="{ name: link.name }"
          active-class="bg-blue-600 hover:bg-blue-600 text-white hover:white"
          class="w-40 cursor-pointer rounded-md px-3 py-1.5 text-slate-500 hover:bg-slate-100">
          {{ link.label }}
        </router-link>
        <a href="https://billing.stripe.com/p/login/7sI14R5oH6s222IaEE"
          active-class="bg-blue-600 hover:bg-blue-600 text-white hover:white"
          class="w-40 cursor-pointer rounded-md px-3 py-1.5 text-slate-500 hover:bg-slate-100">Abrechnung</a>
      </div>
    </header>
    <div class="w-full rounded-md pl-10">
      <router-view />
    </div>
  </div>
</template>

<script lang="ts" setup>
const links = [
  { name: 'admin_users', label: 'Nutzer' },
  { name: 'admin_students', label: 'Schüler' },
]
</script>

<template>
  <div class="mt-5 flex">
    <header class="min-w-fit border-r pr-4 pt-0">
      <div class="mb-3 text-sm uppercase text-gray-500">Einstellungen</div>
      <div class="flex flex-col gap-1">
        <router-link v-for="link in links" :key="link.name" :to="{ name: link.name }"
          active-class="bg-blue-100 !text-blue-700 hover:!text-blue-700 hover:!bg-blue-100"
          class="w-40 cursor-pointer rounded-md px-3 py-1.5 text-gray-500 hover:bg-gray-100">
          {{ link.label }}
        </router-link>
        <a href="https://billing.stripe.com/p/login/7sI14R5oH6s222IaEE" target="_blank"
          active-class="bg-blue-600 hover:bg-blue-600 text-white hover:white"
          class="w-40 cursor-pointer rounded-md px-3 py-1.5 text-gray-500 hover:bg-gray-100 flex justify-between items-center">
          Abrechnung
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
            class="lucide lucide-external-link">
            <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
            <polyline points="15 3 21 3 21 9"></polyline>
            <line x1="10" x2="21" y1="14" y2="3"></line>
          </svg>
        </a>
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

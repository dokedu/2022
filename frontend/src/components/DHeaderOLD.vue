<template>
  <header class="fixed top-0 left-0 right-0 z-[100] flex h-[59px] justify-between border-b bg-white py-2 px-4">
    <div class="flex items-center">
      <router-link :to="{ name: 'entries' }" class="mr-5">
        <DLogo />
      </router-link>
      <div class="hidden sm:flex">
        <DButton v-for="route in routes" :key="route.href" :to="{ name: route.href }" look="link" class="mr-2 space-x-2">
          <DIcon :name="route.icon" size="20" />
          <div>{{ route.name }}</div>
        </DButton>
      </div>
    </div>
    <div class="flex space-x-4">
      <select v-if="store?.organisations?.length > 1" class="rounded-lg border-gray-300">
        <option v-for="organisation in store.organisations" :key="organisation.id" :value="organisation.id">
          {{ organisation.name }}
        </option>
      </select>
      <div class="hidden items-center sm:flex">
        <div class="cursor-pointer rounded-lg p-1 hover:bg-gray-100">
          <IconInfo />
        </div>
      </div>
      <div class="hidden sm:flex">
        <DButton :to="{ name: 'logout' }" look="danger">Abmelden</DButton>
      </div>
    </div>
  </header>
</template>

<script lang="ts" setup>
import { useStore } from '../store/store'
import IconInfo from '../components/icons/IconInfo.vue'
import DButton from '../components/ui/DButton.vue'
import DLogo from '../components/DLogo.vue'
import DIcon from './ui/DIcon.vue'
import { ref } from 'vue'

const routes = ref([
  { name: 'Einträge', icon: 'archive', href: 'entries' },
  { name: 'Schüler', icon: 'users', href: 'students' },
  { name: 'Events', icon: 'calendar', href: 'events' },
  { name: 'Kompetenzen', icon: 'box', href: 'competences' },
  { name: 'Berichte', icon: 'file-text', href: 'reports' },
])

const store = useStore()
</script>

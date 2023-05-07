<template>
  <div v-if="store.organisations.length > 1"
    class="flex print:hidden items-center bg-orange-200 p-2 text-sm text-orange-600">
    Du bist in {{ store.organisations.length }} Organisationen und befindest dich derzeit in
    <strong>&nbsp;"{{ store.organisations.find((a) => a.id === store.organisationId)?.name }}"</strong>.
    <button class="ml-1 block rounded-md bg-orange-300 px-1 py-0.5 text-xs font-medium text-orange-700"
      @click="$router.push('/login/workspaces')">
      Wechseln
    </button>
  </div>
  <div class="block w-full select-none print:hidden">
    <Disclosure v-slot="{ open }" as="nav" class="bg-white shadow-sm">
      <div class="mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 justify-between">
          <div class="flex">
            <router-link class="flex flex-shrink-0 items-center" :to="{ name: 'entries' }">
              <DLogo />
            </router-link>
            <div class="hidden sm:-my-px sm:ml-6 sm:flex sm:space-x-6">
              <router-link v-for="item in navigation" :key="item.name" :to="{ name: item.href }"
                active-class="text-blue-500" :class="[
                  item.current
                    ? 'border-blue-500 text-slate-900'
                    : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700',
                  'inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium',
                ]" :aria-current="item.current ? 'page' : undefined">
                <DIcon :name="item.icon" size="20" />
                <div class="pl-2">{{ item.name }}</div>
              </router-link>
            </div>
          </div>
          <div class="hidden sm:ml-6 sm:flex sm:items-center">
            <!-- Profile dropdown -->
            <Menu as="div" class="relative ml-3">
              <div>
                <MenuButton
                  class="flex rounded-full bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                  <span class="sr-only">Open user menu</span>
                  <div class="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100">
                    <DIcon name="user" size="20" class="first:stroke-slate-200" />
                  </div>
                </MenuButton>
              </div>
              <transition enter-active-class="transition ease-out duration-200"
                enter-from-class="transform opacity-0 scale-95" enter-to-class="transform opacity-100 scale-100"
                leave-active-class="transition ease-in duration-75" leave-from-class="transform opacity-100 scale-100"
                leave-to-class="transform opacity-0 scale-95">
                <MenuItems
                  class="absolute right-0 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
                  <MenuItem v-for="item in userNavigation" :key="item.name" v-slot="{ active }">
                  <router-link :to="{ name: item.href }"
                    :class="[active ? 'bg-slate-100' : '', 'block px-4 py-2 text-sm text-slate-700']">{{ item.name }}
                  </router-link>
                  </MenuItem>
                </MenuItems>
              </transition>
            </Menu>
          </div>
          <div class="-mr-2 flex items-center sm:hidden">
            <!-- Mobile menu button -->
            <DisclosureButton
              class="inline-flex items-center justify-center rounded-md bg-white p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
              <span class="sr-only">Open main menu</span>
              <MenuIcon v-if="!open" class="block h-6 w-6" aria-hidden="true" />
              <XIcon v-else class="block h-6 w-6" aria-hidden="true" />
            </DisclosureButton>
          </div>
        </div>
      </div>

      <DisclosurePanel class="sm:hidden">
        <div class="space-y-1 pt-2 pb-3">
          <DisclosureButton v-for="item in navigation" :key="item.name" as="a" :href="item.href" :class="[
            item?.current
              ? 'flex border-blue-500 bg-blue-50 text-blue-700'
              : 'flex border-transparent text-slate-600 hover:border-slate-300 hover:bg-slate-50 hover:text-slate-800',
            'flex border-l-4 py-2 pl-3 pr-4 text-base font-medium',
          ]" :aria-current="item?.current ? 'page' : undefined">
            <DIcon :name="item.icon" size="20" />
            <div class="pl-2">{{ item.name }}</div>
          </DisclosureButton>
        </div>
        <div class="border-t border-slate-200 pt-4 pb-3">
          <div class="flex items-center px-4">
            <div class="flex-shrink-0">
              <div class="h-10 w-10 rounded-full bg-slate-100" />
            </div>
            <div class="ml-3">
              <div class="text-base font-medium text-slate-800">{{ user.name }}</div>
              <div class="text-sm font-medium text-slate-500">{{ user.email }}</div>
            </div>
          </div>
          <div class="mt-3 space-y-1">
            <DisclosureButton v-for="item in userNavigation" :key="item.name" as="a" :href="item.href"
              class="block px-4 py-2 text-base font-medium text-slate-500 hover:bg-slate-100 hover:text-slate-800">{{
                item.name }}</DisclosureButton>
          </div>
        </div>
      </DisclosurePanel>
    </Disclosure>
  </div>
</template>

<script lang="ts" setup>
import { useStore } from '../store/store'
import DLogo from '../components/DLogo.vue'
import { Disclosure, DisclosureButton, DisclosurePanel, Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import { MenuIcon, XIcon } from '@heroicons/vue/outline'
import DIcon from './ui/DIcon.vue'
import { computed } from 'vue'

const store = useStore()

const user = {
  name: `${store.account.first_name} ${store.account.last_name}`,
  email: store.account.id,
}
const navigation = computed(() => {
  const routes = [
    { name: 'Einträge', icon: 'archive', href: 'entries' },
    { name: 'Schüler', icon: 'users', href: 'students' },
    { name: 'Projekte', icon: 'calendar', href: 'events' },
    { name: 'Kompetenzen', icon: 'box', href: 'competences' },
    { name: 'Berichte', icon: 'file-text', href: 'reports' },
  ]
  if (['owner', 'admin'].includes(store.account.role)) {
    routes.push({ name: 'Admin', icon: 'settings', href: 'admin' })
  }

  return routes
})
const userNavigation = [
  // { name: 'Dein Profil', href: 'entries' },
  // { name: 'Einstellungen', href: 'entries' },
  { name: 'Support', href: 'https://cal.com/team/dokedu/support' },
  { name: 'Abmelden', href: 'logout' },
]
</script>

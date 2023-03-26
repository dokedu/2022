<template>
  <div v-show="store.competences.length > 0"
    class="fixed bottom-5 left-5 max-h-[70vh] max-w-[620px] rounded-2xl border bg-white shadow-md transition hover:shadow-lg">
    <div :class="{ hidden: open }" class="flex min-h-[50px] min-w-[50px] cursor-pointer items-center justify-center"
      @click="open = !open">
      {{ store.competences.length }}
    </div>
    <div :class="{ hidden: !open }" class="relative space-y-2 p-2 pt-4">
      <header class="flex w-full items-center justify-between px-2">
        <div class="text-xs uppercase text-slate-500">Ausgewählte Kompetenzen</div>
        <div
          class="cursor-pointer rounded-lg text-slate-500 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
          tabindex="0" @click="open = !open" @keyup.enter="open = !open">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
            class="feather feather-minimize-2 m-1">
            <polyline points="4 14 10 14 10 20"></polyline>
            <polyline points="20 10 14 10 14 4"></polyline>
            <line x1="14" y1="10" x2="21" y2="3"></line>
            <line x1="3" y1="21" x2="10" y2="14"></line>
          </svg>
        </div>
      </header>
      <div class="max-h-[60vh] overflow-auto">
        <DCompetence v-for="competence in store.competences" :key="competence.id" :competence="competence" removable
          @remove="store.toggleCompetence(competence)" />
      </div>
      <footer class="flex justify-between px-2">
        <span class="cursor-pointer text-slate-500 hover:text-slate-700" @click="removeAllCompetences">Alle
          entfernen</span>
        <DButton look="primary" size="28" @click="documentCompetences">{{ documentButtonText }}</DButton>
      </footer>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useCompetenceStore } from '../../store/competence'
import { computed, ref } from 'vue'
import DCompetence from '../DCompetence.vue'
import DButton from '../DButton.vue'
import { useRoute, useRouter } from 'vue-router'
import { useEntryStore } from '../../store/entry'

const store = useCompetenceStore()
const entryStore = useEntryStore()

const removeAllCompetences = () => {
  if (window.confirm('Alle Kompetenzen entfernen?')) {
    store.competences = []
  }
}

const router = useRouter()
const route = useRoute()

const documentButtonText = computed(() => {
  if (route.name === 'entry_new') {
    return 'Kompetenzen übernehmen'
  } else {
    return 'Kompetenzen dokumentieren'
  }
})

const documentCompetences = async () => {
  if (route.name === 'entry_new') {
    if (entryStore.accounts.length === 0) {
      alert('Bitte erst einen Schüler hinzufügen')
    } else {
      for (const competence of store.competences) {
        entryStore.addCompetence(competence)
      }
    }
  } else {
    await router.push({ name: 'entry_new' })
  }
}

const open = ref(false)
</script>

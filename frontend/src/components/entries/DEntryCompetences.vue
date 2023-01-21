<template>
  <div>
    <div v-show="entryStore.competences?.length > 0" class="mt-8 mb-2 flex items-center justify-between">
      <div class="mb-1 select-none text-xl font-semibold text-slate-700">Kompetenzen</div>
    </div>
    <div>
      <div class="flex flex-col space-y-2">
        <div v-for="eac in entryStore.competences" :key="eac.id">
          <DEntryAccountCompetence
            :eac="eac"
            editable
            @remove="removeCompetence"
            @level="entryStore.setLevel"
          ></DEntryAccountCompetence>
        </div>
      </div>
    </div>
  </div>
  <DCompetenceSearch v-if="isSearchOpen" @close="isSearchOpen = false" @add="addCompetences" />
</template>
<script lang="ts" setup>
import DCompetenceSearch from '../search/DCompetenceSearch.vue'
import DEntryAccountCompetence from '../DEntryAccountCompetence.vue'
import { computed } from 'vue'
import { useEntryStore } from '../../store/entry'
import { Competence } from '../../../../backend/test/types'

const entryStore = useEntryStore()

const isSearchOpen = computed({
  get: () => entryStore.openModal === 'competences',
  set: (value) => (value ? (entryStore.openModal = 'competences') : (entryStore.openModal = '')),
})

const removeCompetence = entryStore.removeCompetence

const addCompetences = (competences: Competence[]) => {
  for (const competence of competences) {
    entryStore.addCompetence(competence)
  }
}
</script>

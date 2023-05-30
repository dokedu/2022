<template>
  <DModal :open="open" @close="$emit('close')">
    <div class="grid h-full grid-cols-5 gap-4 md:grid-cols-9">
      <div class="col-span-5 flex flex-col justify-between">
        <div>
          <input v-model="search" type="text" class="w-full rounded-lg border-gray-300"
            placeholder="Suche nach Fächern, Gruppen oder Kompetenzen" />
          <div v-if="results?.data" class="mt-2 flex max-h-[70vh] flex-col divide-y overflow-auto px-1">
            <div v-for="hit in results?.data?.hits" :key="hit.id">
              <div
                class="my-1 cursor-pointer rounded-lg p-1 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                tabindex="0" @keyup.enter="addCompetence(hit)" @click="addCompetence(hit)">
                <DCompetence :competence="hit" />
              </div>
            </div>
          </div>
        </div>
        <div>
          <div class="flex justify-between p-1 text-gray-500">
            <div class="p-1 text-sm md:text-base">{{ results?.data.nbHits }} Ergebnisse</div>
            <div v-if="results?.data.nbHits - 5 > 0"
              class="cursor-pointer rounded-lg p-1 text-sm hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 md:text-base"
              @click="limit += 5">
              weitere {{ results?.data.nbHits - 5 > 0 ? 5 : results?.data.nbHits - 5 }} anzeigen
            </div>
          </div>
        </div>
      </div>
      <div class="right col-span-5 flex flex-col justify-between md:col-span-4 h-full">
        <div class="max-h-[70vh] h-full flex flex-col">
          <div class="mb-2 font-semibold">Ausgewählte Kompetenzen</div>
          <div class="competences divide-y h-full overflow-auto">
            <div v-for="competence in selected" :key="competence.id">
              <DCompetence class="rounded-lg" removable :competence="competence"
                @remove="selected = selected.filter((el) => el.id !== competence.id)" />
            </div>
          </div>
        </div>
        <div class="actions mt-2 flex w-full justify-end md:mt-0">
          <DButton class="w-full md:w-fit" look="primary" @click="emitCompetences">Kompetenzen hinzufügen</DButton>
        </div>
      </div>
    </div>
  </DModal>
</template>

<script lang="ts" setup>
import DModal from '../ui/DModal.vue'
import { onMounted, onUnmounted, ref, watch } from 'vue'
import supabase from '../../api/supabase'
import useSWRV, { mutate } from 'swrv'
import DCompetence from '../DCompetence.vue'
import DButton from '../ui/DButton.vue'
import { getOrganisationId } from '../../helper/general'

const search = ref('')
const open = ref(true)
const limit = ref(5)
const selected = ref<any[]>([])

interface SearchResults {
  hits: []
  limit: number
  nbHits: number
  offset: 0
}

const meiliSearch = (query: string) =>
  supabase.meiliSearch(getOrganisationId() as string, query, { limit: limit.value })

const { data: results } = useSWRV<{ data: SearchResults }>('/api/search/competences', () => meiliSearch(search.value))

watch(results, async (va) => {
  if (va?.error) {
    await supabase.resetIndex(getOrganisationId() as string)
  }
})

watch(search, () => {
  mutate(
    '/api/search/competences',
    meiliSearch(search.value).then((res) => res),
  )
})

watch(limit, () => {
  mutate(
    '/api/search/competences',
    meiliSearch(search.value).then((res) => res),
  )
})

const emit = defineEmits(['close', 'add'])

const emitCompetences = () => {
  emit('add', selected.value)
  emit('close')
}

// write a function that adds a competence to the selected if it is not already in the selected list (check by id)
const addCompetence = (competence: any) => {
  if (!selected.value.find((c) => c.id === competence.id)) {
    selected.value.push(competence)
  }
}

const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape') {
    // Pressing the ESC key closes the modal.
    emit('close')
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

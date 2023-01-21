<template>
  <div class="-mt-4">
    <DBreadcrumbs :items="() => breadcrumbs" class="mb-4" />

    <div class="mb-4">
      <DInput v-model="search" class="w-full" placeholder="Kompetenz suchen" />
    </div>

    <div v-if="topics?.length > 0">
      <div class="mb-1">Themen</div>
      <div class="flex flex-col divide-y divide-slate-200">
        <div v-for="competence in topics" :key="competence.id">
          <router-link
            :to="{ name: 'competence', params: { id: competence.id } }"
            class="my-1 block rounded-lg hover:bg-slate-100"
          >
            <DCompetence :competence="competence" />
          </router-link>
        </div>
      </div>
    </div>

    <div v-if="competences?.length > 0" class="mt-4">
      <div class="mb-1">Kompetenzen</div>
      <div class="flex flex-col divide-y divide-slate-200">
        <div v-for="competence in competences" :key="competence.id">
          <div
            class="cursor-pointer rounded-md hover:bg-slate-100"
            :class="{
              'bg-blue-100 hover:bg-blue-100': competenceStore.competences.find((el) => el.id === competence.id),
            }"
            @click="competenceStore.toggleCompetence(competence)"
          >
            <DCompetence :competence="competence" />
          </div>
        </div>
      </div>
    </div>
    <DCompetenceSelection />
  </div>
</template>

<script lang="ts" setup>
import { useSWRVS } from '../../../api/helper'
import supabase from '../../../api/supabase'
import { Competence } from '../../../../../backend/test/types/index'
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { mutate } from 'swrv'
import { getOrganisationId } from '../../../helper/general'
import DCompetence from '../../../components/DCompetence.vue'
import DBreadcrumbs from '../../../components/DBreadcrumbs.vue'
import DCompetenceSelection from '../../../components/competences/DCompetenceSelection.vue'
import { useCompetenceStore } from '../../../store/competence'
import DInput from '../../../components/ui/DInput.vue'

const route = useRoute()

const search = ref('')

const competenceStore = useCompetenceStore()

const fetcher = () =>
  supabase
    .from('competences')
    .select('id, name, grades, competence_id, competence_type')
    .eq('competence_id', route.params.id)
    .eq('organisation_id', getOrganisationId())
    .ilike('name', `%${search.value}%`)
    .order('name', { ascending: true })
    .limit(50)

const { data: competencies } = useSWRVS<Competence[]>(`/competences`, fetcher())

onMounted(() => {
  mutate(
    `/competences`,
    fetcher().then((res) => res.data),
  )
  mutate(
    `/parents/competences/tree`,
    fetchCompetenceParents().then((res) => res.data),
  )
})

const fetchCompetenceParents = () =>
  supabase.rpc<Competence>('get_competence_tree', { _competence_id: route.params.id }).select()

const { data: parents } = useSWRVS<Competence[]>(`/parents/competences/tree`, fetchCompetenceParents())

const breadcrumbs = computed(() => {
  const crumbs = [{ name: 'Kompetenzen', to: { name: 'competences' } }]
  if (!(parents && parents.value && parents.value.length > 0)) return crumbs

  for (const parent of parents.value.slice().reverse()) {
    crumbs.push({ name: parent.name, to: { name: 'competence', params: { id: parent.id } } })
  }

  return crumbs
})

const topics = computed(() => competencies?.value?.filter((el) => el.competence_type === 'group'))
const competences = computed(() => competencies?.value?.filter((el) => el.competence_type === 'competence'))

watch(
  () => route.params.id,
  () => {
    mutate(
      `/competences`,
      fetcher().then((res) => res.data),
    )
    mutate(
      `/parents/competences/tree`,
      fetchCompetenceParents().then((res) => res.data),
    )
  },
)

watch(search, () => {
  mutate(
    `/competences`,
    fetcher().then((res) => res.data),
  )
})
</script>

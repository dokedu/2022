<template>
  <div class="mt-4 flex flex-col divide-y divide-gray-200">
    <div v-for="subject in subjects" :key="subject.id" class="">
      <router-link :to="{ name: 'competence', params: { id: subject.id } }"
        class="my-1 block rounded-lg p-2 hover:bg-gray-100">{{ subject.name }}</router-link>
    </div>
  </div>

  <DCompetenceSelection />
</template>

<script lang="ts" setup>
import { useSWRVS } from '../../api/helper'
import supabase from '../../api/supabase'
import { Competence } from '../../../../backend/test/types/index'
import { ref } from 'vue'
import { getOrganisationId } from '../../helper/general'
import DCompetenceSelection from '../../components/competences/DCompetenceSelection.vue'

const search = ref('')

const fetcher = () =>
  supabase
    .from('competences')
    .select('id, name, grades, competence_id', { count: 'exact' })
    .eq('competence_type', 'subject')
    .eq('organisation_id', getOrganisationId())
    .ilike('name', `%${search.value}%`)
    .order('name', { ascending: true })
    .is('deleted_at', null)
    .limit(50)

const { data: subjects } = useSWRVS<{ data: Competence[] }>(`/search/subjects`, fetcher())
</script>

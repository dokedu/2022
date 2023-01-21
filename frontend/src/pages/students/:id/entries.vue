<template>
  <div class="flex items-start space-x-4">
    <DButton @click="position -= 1">Previous</DButton>
    <div class="w-full">
      <router-link v-for="entry in entries" :key="entry.id"
        class="mb-2 flex w-full flex-col justify-between rounded-lg border bg-white py-4 px-5 hover:shadow"
        :to="{ name: 'entry', params: { id: entry.id } }">
        <div v-show="loading" class="mb-1 text-blue-500">Lädt gerade</div>
        <div>
          <div>{{ entry.id }}</div>
          <div class="mb-1 text-sm font-medium text-slate-600">{{ parseDate(entry.created_at) }}</div>
          <div class="max-h-[50px] overflow-hidden text-ellipsis" v-html="renderEntryBody(entry.body)"></div>
        </div>
        <div class="mt-2 text-sm font-medium text-slate-600">
          {{ entry?.account?.first_name }} {{ entry?.account?.last_name }}
        </div>
        <div>
          <div v-if="
            entry?.entry_account_competences?.filter(
              (el) => el.deleted_at === null && el.account_id === route.params.id,
            ).length > 0
          " class="mt-6">
            <div class="mb-2 cursor-pointer text-sm uppercase text-slate-500">
              {{ reduceEACsToCompetences(entry.entry_account_competences).length }} Kompetenzen
            </div>
            <div class="flex flex-col space-y-3">
              <DEntryAccountCompetence v-for="eac in reduceEACsToCompetences(entry.entry_account_competences)"
                :key="eac.id" :eac="eac" />
            </div>
          </div>
        </div>
      </router-link>
    </div>
    <DButton @click="position += 1">Next</DButton>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../../api/supabase'
import { useSWRVS } from '../../../api/helper'
import { useRoute } from 'vue-router'
import { parseDate } from '../../../helper/parseDate'
import { renderEntryBody } from '../../../helper/renderJSON'
import { ref, watch } from 'vue'
import { mutate } from 'swrv'
import { reduceEACsToCompetences } from '../../../store/entry'
import DButton from '../../../components/ui/DButton.vue'
import DEntryAccountCompetence from '../../../components/DEntryAccountCompetence.vue'

const route = useRoute()

const fetchStudentEntries = () =>
  supabase
    .from('view_entries')
    .select(
      'id, body, created_at, entry_accounts (*, account:account_id (*)), entry_files (*), entry_events (*,  event:event_id (*)), date,account:accounts ( * ), entry_account_competences (*, competence:competence_id (*))',
    )
    .is('deleted_at', null)
    .eq('entry_accounts.account_id', route.params.id)
    .order('date', { ascending: false })
    .range(0 + position.value, 0 + position.value)

const position = ref(0)
const loading = ref(false)

watch([position], () => {
  loading.value = true
  mutate(
    `/students/${route.params.id}/entries_all`,
    fetchStudentEntries().then((res) => {
      loading.value = false
      return res.data
    }),
  )
})

const { data: entries } = useSWRVS<Entry[]>(`/students/${route.params.id}/entries_all`, fetchStudentEntries())
</script>

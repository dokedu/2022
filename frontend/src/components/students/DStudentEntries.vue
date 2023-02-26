<template>
  <div v-if="entries?.length > 0" class="mt-10">
    <div class="flex justify-between">
      <div class="mb-2 text-xl">Einträge</div>
      <router-link :to="{ name: 'entries', query: { students: $route.params.id } }"
        class="cursor-pointer text-blue-500 hover:text-blue-700">alle
        Einträge</router-link>
    </div>
    <div class="grid h-36 w-full grid-cols-1 gap-2 rounded-lg sm:grid-cols-3">
      <router-link v-for="entry in entries" :key="entry.id"
        class="flex w-full flex-col justify-between rounded-lg border bg-white py-4 px-5 hover:shadow"
        :to="{ name: 'entry', params: { id: entry.id } }">
        <div>
          <div class="mb-1 text-sm font-medium text-slate-600">{{ parseDate(entry.created_at) }}</div>
          <div class="max-h-[50px] overflow-hidden text-ellipsis" v-html="renderEntryBody(entry.body)"></div>
        </div>
        <div class="mt-2 text-sm font-medium text-slate-600">
          {{ entry.account.first_name }} {{ entry.account.last_name }}
        </div>
      </router-link>
    </div>
  </div>
  <div v-if="entries?.length === 0" class="mt-10">
    <div class="mb-2 text-xl">Einträge</div>
    <div class="flex h-36 w-full flex-col items-center justify-center rounded-lg border">
      <div class="mb-4 text-slate-500">Keine Einträge gefunden.</div>
      <DButton look="primary" size="28" :to="{ name: 'entry_new' }">Eintrag erstellen</DButton>
    </div>
  </div>
  <div v-if="!entries" class="mt-10">
    <div class="mb-2 text-xl">Einträge</div>
    <div class="flex h-36 w-full space-x-2 rounded-lg">
      <div class="h-full w-full animate-pulse rounded-lg border bg-slate-50"></div>
      <div class="h-full w-full animate-pulse rounded-lg border bg-slate-50"></div>
      <div class="h-full w-full animate-pulse rounded-lg border bg-slate-50"></div>
    </div>
  </div>
</template>

<script lang="ts">
import supabase from '../../api/supabase'
import { useSWRVS } from '../../api/helper'
import { parseDate } from '../../helper/parseDate'
import { renderEntryBody } from '../../helper/renderJSON'
import DButton from '../ui/DButton.vue'

export default {
  name: 'DStudentEntries',
  components: { DButton },

  props: {
    student: {
      type: Object,
      required: true,
    },
  },
  setup(props: any) {
    const fetchStudentEntries = () =>
      supabase
        .from('view_entries')
        .select(
          'id, body, date, entry_accounts!inner (id, entry_id, account_id), created_at, account:account_id (id, first_name, last_name)',
        )
        .eq('entry_accounts.account_id', props.student.id)
        .order('date', { ascending: false })
        .limit(3)

    const { data: entries } = useSWRVS<Entry[]>(`/students/${props.student.id}/entries`, fetchStudentEntries())

    return {
      entries,
      parseDate,
      renderEntryBody,
    }
  },
}
</script>

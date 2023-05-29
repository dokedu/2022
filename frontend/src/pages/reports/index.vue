<template>
  <div class="mt-4" data-cy="reports">
    <DTable :items="reports" :columns="tableColumns" @open="clickEntry">
      <template #student="{ column }">
        {{ `${column.first_name} ${column.last_name}` }}
      </template>
      <template #from="{ column }">
        {{ parseDateCalendar(column) }}
      </template>
      <template #to="{ column }">
        {{ parseDateCalendar(column) }}
      </template>
      <template #status="{ column }">
        <DReportStatus :status="column" />
      </template>
      <template #created_at="{ column }">
        {{ parseDate(column) }}
      </template>
    </DTable>
  </div>

  <div v-show="!reports || reports?.length === 0"
    class="flex w-full items-center justify-center rounded-md border border-dashed p-8 text-gray-600">
    <div class="">Hier gibt es noch keine Berichte.</div>
  </div>
</template>

<script lang="ts" setup>
import { ref, watch } from 'vue'
import supabase from '../../api/supabase'
import { useSWRVS } from '../../api/helper'
import { mutate } from 'swrv'
import { parseDate, parseDateCalendar } from '../../helper/parseDate'
import { getOrganisationId } from '../../helper/general'
import DReportStatus from '../../components/reports/DReportStatus.vue'
import { Report } from '../../../../backend/test/types'
import DTable from '../../components/ui/DTable.vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const tableColumns = [
  { name: 'Schüler', key: 'student', sortable: false },
  { name: 'Von', key: 'from', sortable: false },
  { name: 'Bis', key: 'to', sortable: false },
  { name: 'Status', key: 'status', sortable: false },
  { name: 'Erstellt am', key: 'created_at', sortable: false },
]

function clickEntry(report: Report) {
  router.push({ name: 'report', params: { id: report.id } })
}

const search = ref('')

const fetchReports = () => {
  let fetcher = supabase
    .from('reports')
    .select('*, student:student_account_id!inner (first_name,last_name)')
    .eq('student.organisation_id', getOrganisationId())
    .limit(50)
    .order('created_at', { ascending: false })

  if (search.value) {
    //fetcher = fetcher.or(`student_account_id_fk.ilike.%${search.value}%,body.ilike.%${search.value}%`)
  }

  return fetcher
}

const { data: reports } = useSWRVS<(Report & { student: { first_name: string; last_name: string } })[]>(
  `/reports`,
  fetchReports(),
)

watch(search, async (s: string) => {
  await mutate(`/reports`, await fetchReports().then((res) => res.data))
})

</script>

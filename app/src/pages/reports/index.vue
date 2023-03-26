<template>
  <div class="mt-4" data-cy="reports">
    <router-link v-for="report in reports" :key="report.id"
      class="mb-2 grid grid-cols-4 items-center gap-2 rounded-lg border border-slate-300 p-3 hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 md:grid-cols-4"
      :to="{ name: 'report', params: { id: report.id } }" data-cy="report-link">
      <span class="min-w-max">{{ report.student.first_name }} {{ report.student.last_name }}</span>
      <div class="text-sm">{{ parseDateCalendar(report.from) }} - {{ parseDateCalendar(report.to) }}</div>
      <div class="min-w-max">
        <DReportStatus :status="report.status" />
      </div>
      <div class="col-span-1 min-w-max">{{ parseDate(report.created_at) }}</div>
    </router-link>
  </div>

  <div v-show="!reports" class="text-slate-600">Hier gibt es noch keine Reports.</div>

  <div v-show="reports?.length === 0"
    class="flex w-full items-center justify-center rounded-md border border-dashed p-8 text-slate-600">
    <div class="">Hier gibt es noch keine Berichte.</div>
  </div>

  <!-- TODO: Pagination -->
</template>
<script lang="ts">
import { ref, watch } from 'vue'
import supabase from '../../api/supabase'
import { useSWRVS } from '../../api/helper'
import { mutate } from 'swrv'
import { parseDate, parseDateCalendar } from '../../utils/parseDate'
import { getOrganisationId } from '../../utils/general'
import DReportStatus from '../../components/d-report/DReportStatus.vue'
import { Report } from '../../../../backend/test/types'

export default {
  components: { DReportStatus },
  setup() {
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

    return {
      search,
      reports,
      parseDateCalendar,
      parseDate,
    }
  },
}
</script>

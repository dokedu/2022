<template>
  <div class="mb-4 flex items-center justify-between space-x-2">
    <div class="flex space-x-2">
      <DFilterDropdown v-if="teachers?.length > 0" id="teacher" v-model="filters.account_id" :options="teachersOptions"
        data-cy="student" label="Lehrer" />
      <DFilterDropdown v-if="students?.length > 0" id="students" v-model="filters.student_id" :options="studentsOptions"
        data-cy="student" label="Schüler" />
      <DFilterTags v-model="currentTags" label="Tags"></DFilterTags>
    </div>
    <div class="flex space-x-2">
      <div class="flex flex-col" v-if="false">
        <label for="search" class="mb-1 text-xs font-medium text-slate-500">Suche</label>
        <input id="search" v-model="filters.search" type="text" placeholder="Suche"
          class="rounded-lg border-slate-300 py-1.5 px-3 text-sm shadow-sm" />
      </div>
      <div class="flex flex-col">
        <label for="limit" class="mb-1 text-xs font-medium text-slate-500">Limit</label>
        <select id="limit" v-model="filters.limit"
          class="min-w-[60px] rounded-lg border border-slate-300 py-1.5 px-3 shadow-sm sm:text-sm">
          <option :value="5">5</option>
          <option :value="10">10</option>
          <option :value="25">25</option>
          <option :value="50">50</option>
          <option :value="100">100</option>
        </select>
      </div>
    </div>
  </div>
  <div>
    <div v-if="entries?.data?.length > 0" data-cy="entries">
      <DTable v-model:sorting="sorting" data-cy="entries-table" :items="tableEntries" :columns="tableColumns"
        @open="tableOnRowClick">
        <template #teacher="{ column }">
          <div class="min-w-[100px]" data-cy="entry-teacher">{{ column }}</div>
        </template>
        <template #body="{ column }">
          <div class="min-w-[320px]" data-cy="entry-body">{{ column }}</div>
        </template>
      </DTable>
    </div>
    <div v-else class="pt-12 text-center text-slate-500">Keine Einträge gefunden.</div>
  </div>
  <div class="mt-4">
    <DPagination v-show="entries?.count > 0 && entries?.count > limit" :limit="parseInt(limit)" :count="entries?.count"
      :offset="offset" @change="setOffset" />
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../api/supabase'
import { useSWRVS, useSWRVX } from '../../api/helper'
import { renderEntryBodyText } from '../../helper/renderJSON'
import { parseDate, parseDateCalendar } from '../../helper/parseDate'
import { Account, Entry, Tag } from '../../../../backend/test/types/index'
import { getOrganisationId } from '../../helper/general'
import { computed, onMounted, ref, toRef, watch } from 'vue'
import { mutate } from 'swrv'
import DPagination from '../../components/ui/DPagination.vue'
import { useEntryStore } from '../../store/entry'
import { storeToRefs } from 'pinia'
import DDropdown from '../../components/ui/DDropdown.vue'
import DTable from '../../components/ui/DTable.vue'
import { useRouter } from 'vue-router'
import DTagList from '../../components/ui/DTagList.vue'
import DFilterDropdown from '../../components/ui/DFilterDropdown.vue'
import DFilterTags from '../../components/ui/DFilterTags.vue'

const entryStore = useEntryStore()
const router = useRouter()

const { filters } = storeToRefs(entryStore)

const limit = toRef(entryStore.filters, 'limit')
const account = toRef(entryStore.filters, 'account_id')
const student = toRef(entryStore.filters, 'student_id')
const offset = toRef(entryStore.filters, 'offset')
const search = toRef(entryStore.filters, 'search')
const currentTags = ref([])

const sorting = ref({ key: 'created_at', order: 'desc' })

const fetchTeachers = () => {
  return supabase
    .from('accounts')
    .select('*')
    .in('role', ['teacher', 'admin', 'teacher_guest', 'owner'])
    .eq('organisation_id', getOrganisationId())
    .is('deleted_at', null)
    .limit(200)
}
const fetchStudents = () => {
  return supabase
    .from('accounts')
    .select('*')
    .in('role', ['student'])
    .eq('organisation_id', getOrganisationId())
    .is('deleted_at', null)
    .limit(200)
}

const entriesQuery = computed(() => {
  const studentSelect = student.value ? 'entry_accounts!inner (*),' : ''

  let query = supabase
    .from('view_entries')
    .select(
      `id, body, created_at, date, account_id, ${studentSelect} account:account_id!inner (id, first_name, last_name, organisation_id) ${currentTags.value.length > 0 ? ', entry_tags!inner (tag_id)' : ''
      }`,
      { count: 'exact' },
    )
    .is('deleted_at', null)
    .eq('account.organisation_id', getOrganisationId())
    .order(sorting.value.key, { ascending: sorting.value.order === 'asc' })
    .range(offset.value, offset.value + parseInt(limit.value as string) - 1)

  if (account.value) {
    query = query.eq('account_id', account.value)
  }

  if (currentTags.value?.length > 0) {
    query = query.in(
      'entry_tags.tag_id',
      currentTags.value.map((t) => t.id),
    )
  }

  if (student.value) {
    query = query.eq('entry_accounts.account_id', student.value)
  }

  return query
})

const fetchEntries = async () => {
  return entriesQuery.value.then((res) => res)
}

watch(
  [limit, student, account, sorting, currentTags],
  () => {
    offset.value = 0
    mutate('/entries', fetchEntries())
  },
  { deep: true, immediate: true },
)

onMounted(() => {
  offset.value = 0
  limit.value = 10
  mutate(`/entries`, fetchEntries())
  mutate(
    `/students`,
    fetchStudents().then((res) => res.data),
  )
})

const setOffset = (val: number) => {
  if (val < 0) return
  if (val > (entries?.value?.count || -1)) return

  offset.value = val

  mutate(
    `/entries`,
    fetchEntries().then((res) => res),
  )
}

const studentsOptions = computed(() => {
  return students.value?.map((student: Account) => {
    return {
      value: student.id,
      label: `${student.first_name} ${student.last_name}`,
    }
  })
})

const teachersOptions = computed(() => {
  return teachers.value?.map((teacher: Account) => {
    return {
      value: teacher.id,
      label: `${teacher.first_name} ${teacher.last_name}`,
    }
  })
})

const tableColumns = [
  { name: 'Lehrer', key: 'teacher', sortable: false },
  {
    name: 'Text',
    key: 'body',
    sortable: false,
  },
  { name: 'Datum', key: 'date', sortable: true },
  { name: 'Erstellt am', key: 'created_at', sortable: true },
]

function tableOnRowClick(entry: Entry) {
  router.push({ name: 'entry', params: { id: entry.id } })
}

const { data: entries } = useSWRVX<{ data: (Entry & { account: Account })[]; count: number }>('/entries', fetchEntries)
const { data: teachers } = useSWRVS<Account[]>('/teachers', fetchTeachers())
const { data: students } = useSWRVS<Account[]>('/students', fetchStudents())

const tableEntries = computed(() => {
  return entries?.value?.data.map((e) => {
    return {
      id: e.id,
      teacher: e.account?.first_name + ' ' + e.account?.last_name,
      date: parseDateCalendar(e.date),
      created_at: parseDate(e.created_at),
      body: renderEntryBodyText(e.body as JSON).substring(0, 42),
    }
  })
})
</script>

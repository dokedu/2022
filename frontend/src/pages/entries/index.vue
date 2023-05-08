<template>
  <div>
    <div class="mb-4 flex items-center justify-between space-x-2">
      <div class="flex space-x-2">
        <DFilterDropdown id="teacher" v-model="accountFilter" :options="teachersOptions" data-cy="student"
          label="Lehrer" />
        <DFilterDropdown id="students" v-model="studentFilter" :options="studentsOptions" data-cy="student"
          label="Schüler" />
        <DFilterTags v-model="tagsFilter" label="Tags"></DFilterTags>
      </div>
      <div class="flex space-x-2">
        <!--
        <div class="flex flex-col">
          <label for="search" class="mb-1 text-xs font-medium text-slate-500">Suche</label>
          <input id="search" v-model="filters.search" type="text" placeholder="Suche"
            class="rounded-lg border-slate-300 py-1.5 px-3 text-sm shadow-sm" />
        </div>
        -->
        <div class="flex flex-col">
          <label for="limit" class="mb-1 text-xs font-medium text-slate-500">Limit</label>
          <select id="limit" v-model="limit"
            class="min-w-[60px] rounded-lg border border-slate-300 py-1.5 px-3 shadow-sm sm:text-sm">
            <option v-for="option in limitOptions" :key="option" :value="option">{{ option }}</option>
          </select>
        </div>
      </div>
    </div>
    <div>
      <div v-if="entries !== undefined && entries?.data?.length > 0" data-cy="entries">
        <DTable v-model:sorting="sorting" data-cy="entries-table" :items="tableEntries" :columns="tableColumns"
          @open="onTableRowClick">
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
    <div class="mt-4" v-if="entries !== undefined">
      <DPagination v-show="entries?.count > 0 && entries?.count > limitInt" :limit="limitInt" :count="entries?.count"
        :offset="offsetInt" @change="setOffset" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../api/supabase'
import { useSWRVX } from '../../api/helper'
import { renderEntryBodyText } from '../../helper/renderJSON'
import { parseDate, parseDateCalendar } from '../../helper/parseDate'
import { Account, Entry, Tag } from '../../../../backend/test/types/index'
import { getOrganisationId } from '../../helper/general'
import { computed, ref, watch } from 'vue'
import DPagination from '../../components/ui/DPagination.vue'
import DTable from '../../components/ui/DTable.vue'
import { useRouter } from 'vue-router'
import DFilterDropdown from '../../components/ui/DFilterDropdown.vue'
import DFilterTags from '../../components/ui/DFilterTags.vue'
import { useRouteQuery } from '@vueuse/router'
import useSWRV from 'swrv'

const router = useRouter()

// Page Filters
const limitOptions = [5, 10, 25, 50, 100]
const limit = useRouteQuery<string>('limit', "10")
const limitInt = computed(() => parseInt(limit.value))
const offset = useRouteQuery<string>('offset', "0")
const offsetInt = computed(() => parseInt(offset.value))
//const search = toRef(entryStore.filters, 'search')
const accountFilter = useRouteQuery<string | null>('accounts')
const studentFilter = useRouteQuery<string | null>('students')
const tagsFilter = ref<Tag[]>([])

const key = useRouteQuery<string>('sortkey', "created_at")
const order = useRouteQuery<string>('order', "desc")

const sorting = computed({
  get() {
    return {
      key: key.value,
      order: order.value,
    }
  },
  set(value) {
    key.value = value.key
    order.value = value.order
  },
})

const transformToOptions = (arr: Account[]) => {
  if (arr === null) return []
  if (arr === undefined) return []
  if (arr.length === 0) return []
  if (arr[0] === undefined) return []
  if (arr[0].id === undefined) return []
  return arr.map((item) => {
    return {
      value: item.id,
      label: `${item.first_name} ${item.last_name}`,
    }
  })
}
const studentsOptions = computed(() => {
  if (students.value === null) return []
  if (students.value === undefined) return []
  if (students.value.length === 0) return []
  return transformToOptions(students.value)
})
const teachersOptions = computed(() => {
  if (teachers.value === null) return []
  if (teachers.value === undefined) return []
  if (teachers.value.length === 0) return []
  return transformToOptions(teachers.value)
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

function onTableRowClick(entry: Entry) {
  router.push({ name: 'entry', params: { id: entry.id } })
}

const { data: teachers } = useSWRV<Account[]>('/entries/?/teachers', async () => supabase
  .from('accounts')
  .select('*')
  .in('role', ['teacher', 'admin', 'teacher_guest', 'owner'])
  .eq('organisation_id', getOrganisationId())
  .is('deleted_at', null)
  .limit(200).then((res) => res.data as Account[]))

const { data: students } = useSWRV<Account[]>('/entries/?/students', async () => supabase
  .from('accounts')
  .select('*')
  .in('role', ['student'])
  .eq('organisation_id', getOrganisationId())
  .is('deleted_at', null)
  .limit(200).then((res) => res.data as Account[]))

const { data: entries, mutate: refreshEntries } = useSWRVX<{ data: (Entry & { account: Account })[]; count: number }>('/entries', async () => {
  const studentSelect = studentFilter.value ? 'entry_accounts!inner (*),' : ''
  const tagsSelect = tagsFilter.value !== null && tagsFilter.value.length > 0 ? ', entry_tags!inner (tag_id)' : ''

  const selectQuery = `id, body, created_at, date, account_id, ${studentSelect} account:account_id!inner (id, first_name, last_name, organisation_id) ${tagsSelect}`

  let query = supabase
    .from('view_entries')
    .select(selectQuery, { count: 'exact' })
    .is('deleted_at', null)
    .eq('account.organisation_id', getOrganisationId())
    .order(sorting.value.key, { ascending: sorting.value.order === 'asc' })
    .range(parseInt(offset.value), parseInt(offset.value) + parseInt(limit.value) - 1)

  if (accountFilter.value) {
    query = query.eq('account_id', accountFilter.value)
  }

  if (tagsFilter.value !== null && tagsFilter.value?.length > 0) {
    query = query.in(
      'entry_tags.tag_id',
      tagsFilter.value.map((t) => t.id),
    )
  }

  if (studentFilter.value) {
    query = query.eq('entry_accounts.account_id', studentFilter.value)
  }

  const res = await query
  return {
    data: res.data as (Entry & { account: Account })[],
    count: res.count as number,
  }
}
)

// [limit, studentFilter, accountFilter, sorting, tagsFilter],

watch(
  limit,
  async (a, b) => {
    if (JSON.stringify(a) === JSON.stringify(b)) return
    offset.value = "0"
    await refreshEntries()
  },
  { immediate: true, deep: true },
)

watch(
  studentFilter,
  async (a, b) => {
    if (JSON.stringify(a) === JSON.stringify(b)) return
    offset.value = "0"
    await refreshEntries()
  },
  { immediate: true, deep: true },
)

watch(
  accountFilter,
  async (a, b) => {
    if (JSON.stringify(a) === JSON.stringify(b)) return
    offset.value = "0"
    await refreshEntries()
  },
  { immediate: true, deep: true },
)

watch(
  sorting,
  async (a, b) => {
    if (JSON.stringify(a) === JSON.stringify(b)) return
    offset.value = "0"
    await refreshEntries()
  },
  { immediate: true, deep: true },
)

watch(
  tagsFilter,
  async (a, b) => {
    offset.value = "0"
    await refreshEntries()
    await refreshEntries()
  },
  { deep: true },
)


const setOffset = async (val: number) => {
  console.log(val, (val).toString())

  console.log('a')
  if (val < 0) return
  console.log('b')
  if (val > (entries?.value?.count || -1)) return
  console.log('c')

  offset.value = (val).toString()

  await refreshEntries()
  await refreshEntries()
}

const tableEntries = computed(() => {
  if (!entries?.value) return []
  return entries?.value?.data.map((entry) => {
    return {
      id: entry.id,
      teacher: entry.account?.first_name + ' ' + entry.account?.last_name,
      date: parseDateCalendar(entry.date),
      created_at: parseDate(entry.created_at),
      body: renderEntryBodyText(entry.body as JSON).substring(0, 42),
    }
  })
})
</script>

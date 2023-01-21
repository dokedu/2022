<template>
  <div class="mt-4">
    <div class="mb-4 flex space-x-4">
      <DInput v-model="search" class="w-full" placeholder="Schüler suchen"></DInput>
    </div>

    <DTable v-model:sorting="sorting" :items="students?.data" :columns="tableColumns" @open="tableOnRowClick" />

    <div class="mt-4">
      <DPagination
        v-show="students?.count > 0 && students?.count > limit"
        :limit="parseInt(limit)"
        :count="students?.count"
        :offset="offset"
        @change="setOffset"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../api/supabase'
import { useSWRVX } from '../../api/helper'
import { Account } from '../../../../backend/test/types/index'
import { computed, onMounted, ref, watch } from 'vue'
import { mutate } from 'swrv'
import { getOrganisationId } from '../../helper/general'
import DPagination from '../../components/ui/DPagination.vue'
import DTable from '../../components/ui/DTable.vue'
import { useRouter } from 'vue-router'
import DInput from '../../components/ui/DInput.vue'

const search = ref('')
const router = useRouter()

const tableColumns = [
  { name: 'Vorname', key: 'first_name', sortable: true },
  { name: 'Nachname', key: 'last_name', sortable: true },
  { name: 'Klassenstufe', key: 'grade', sortable: true },
]

const sorting = ref({ key: 'last_name', order: 'desc' })

function tableOnRowClick(student: any) {
  router.push({ name: 'student', params: { id: student.id } })
}

const limit = ref<number>(10)
const offset = ref(0)

const accountsQuery = computed(() => {
  let fetcher = supabase
    .from('accounts')
    .select('id, first_name, last_name, grade', { count: 'exact' })
    .eq('organisation_id', getOrganisationId())
    .eq('role', 'student')
    .is('deleted_at', null)
    .order(sorting.value.key, { ascending: sorting.value.order === 'asc' })
    .range(offset.value, offset.value + limit.value - 1)

  if (search.value) {
    fetcher = fetcher.or(`first_name.ilike.%${search.value}%,last_name.ilike.%${search.value}%`)
  }

  return fetcher
})

const fetchAccounts = async () => {
  return accountsQuery.value.then((res) => res)
}

const { data: students } = useSWRVX<Account[]>(`/students`, fetchAccounts)

watch(
  [limit, search, sorting],
  () => {
    offset.value = 0
    mutate(`/students`, fetchAccounts())
  },
  {
    deep: true,
  },
)

onMounted(() => {
  mutate(`/students`, fetchAccounts())
})

const setOffset = (val: number) => {
  if (val < 0) return
  if (val > students?.value?.count) return

  offset.value = val

  mutate(`/students`, fetchAccounts())
}
</script>

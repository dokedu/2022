<template>
  <div>
    <div v-show="accounts?.length > 0" class="mt-8">
      <div class="flex items-center justify-between">
        <div class="mb-1 select-none text-xl font-semibold text-slate-700">Schüler</div>
      </div>
      <div>
        <div v-if="accounts" class="flex flex-col divide-y">
          <div v-for="student in accounts" :key="student.id" class="my-1 flex items-center justify-between pt-2">
            <div class="">{{ student.account.first_name }} {{ student.account.last_name }}</div>
            <div class="cursor-pointer rounded-lg hover:bg-slate-100" @click="removeAccount(student)">
              <IconX />
            </div>
          </div>
        </div>
      </div>
    </div>

    <DModal :open="open" @close="open = false">
      <div class="flex min-h-[450px] flex-col justify-between">
        <div>
          <div class="mb-1">
            <input v-model="search" type="text" class="w-full rounded-lg border-slate-300"
              placeholder="Schüler suchen" />
            <div class="mt-1 flex flex-wrap">
              <div v-for="account in accounts" :key="account.id" class="m-1 ml-0 flex rounded-lg border p-1 text-sm">
                {{ account.account.first_name }} {{ account.account.last_name }}
                <span class="ml-1 cursor-pointer rounded-lg hover:bg-slate-100" @click="removeAccount(account)">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="2 0 20 20" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                    class="feather feather-x stroke-slate-500">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </span>
              </div>
            </div>
          </div>
          <div class="mb-2 flex flex-col space-y-1">
            <div v-for="student in filteredStudents" :key="student.id"
              class="cursor-pointer rounded-lg p-1 hover:bg-slate-100" @click="onAddAccount(student)">
              {{ student.first_name }} {{ student.last_name }}
            </div>
            <div v-show="students?.count === 0" class="p-1">Keine Ergebnisse</div>
          </div>
        </div>

        <DPagination v-show="students?.count > 0 && students?.count > a.limit" :limit="a.limit" :count="students?.count"
          :offset="a.offset" @change="setOffset" />
      </div>
    </DModal>
  </div>
</template>
<script lang="ts" setup>
import supabase from '../../api/supabase'
import { useSWRVX } from '../../api/helper'
import DModal from '../DModal.vue'
import { useEntryStore } from '../../store/entry'
import DPagination, { paginationProps } from '../DPagination.vue'
import { computed, ref, watch } from 'vue'
import { mutate } from 'swrv'
import { storeToRefs } from 'pinia'
import IconX from '../icons/IconX.vue'
import { getOrganisationId } from '../../utils/general'
import { Account } from '../../../../backend/test/types/index'

const entryStore = useEntryStore()

const { accounts } = storeToRefs(entryStore)

const open = computed({
  get: () => entryStore.openModal === 'students',
  set: (value) => (value ? (entryStore.openModal = 'students') : (entryStore.openModal = '')),
})

const a = ref(paginationProps)
a.value.limit = 10

const search = ref('')

const removeAccount = entryStore.removeAccount

const studentsQuery = computed(() =>
  supabase
    .from('accounts')
    .select('*', { count: 'exact' })
    .eq('organisation_id', getOrganisationId())
    .eq('role', 'student')
    .is('deleted_at', null)
    .or(orSearch.value)
    .range(a.value.offset, a.value.offset + a.value.limit - 1),
)

const fetchStudents = async () => {
  return studentsQuery.value.then((res) => res)
}

const orSearch = computed(() => {
  const searchTerm = search.value.trim()
  if (searchTerm.length === 0) return 'first_name.ilike.%%'
  const values = searchTerm.split(' ')
  let query = ''

  for (const val of values) {
    if (!val) continue
    query += `first_name.ilike.%${val}%,last_name.ilike.%${val}%,`
  }

  return query.slice(0, -1)
})

const { data: students } = useSWRVX<{ data: Account[]; count: number }>(`/entries/new/students`, fetchStudents)

const selectedStudents = computed(() => entryStore.accounts.map((account) => account.account_id))
const filteredStudents = computed(() =>
  students.value?.data.filter((student: Account) => !selectedStudents.value.includes(student.id)),
)

const onAddAccount = (student: Account) => {
  entryStore.addAccount(student)

  if (!filteredStudents.value?.length) {
    search.value = ''
  }
}

watch(search, (value, old) => {
  if (value === old) return

  mutate(`/entries/new/students`, fetchStudents())
})

const setOffset = (val: number) => {
  if (val < 0) return
  if (val > (students?.value?.count || -1)) return

  a.value.offset = val

  mutate(`/entries/new/students`, fetchStudents())
}
</script>

<template>
  <div>
    <div class="mb-3 text-xl font-medium">Schüler</div>
    <div class="flex flex-col">
      <div class="mb-5 flex">
        <DInput v-model="state.search" name="search_students" class="mr-5 w-full" placeholder="Schüler suchen"></DInput>
        <DButton look="primary" @click="onOpenCreate"> Schüler erstellen </DButton>
      </div>
      <div class="mb-5">
        <DToggle v-model="state.showArchived">Zeige archivierte</DToggle>
      </div>

      <DTable :items="users?.data || []" :columns="tableColumns" @open="onOpen">
        <template #role>
          <span class="inline-flex rounded-full bg-slate-100 px-2 text-xs font-medium leading-5 text-slate-800">
            Schüler
          </span>
        </template>
        <template #birthday="{ item }">
          {{ item.birthday ? parseDateCalendar(item.birthday) : '-' }}
        </template>
        <template #grade="{ item }">
          {{ item.grade }}
        </template>
      </DTable>

      <DPagination v-if="users?.count > 10" :limit="10" :offset="offset" :count="users?.count"
        @change="offset = $event"></DPagination>
    </div>
  </div>

  <DModal :open="create !== null" modal-class="sm:max-w-[500px]" @close="create = null">
    <div class="flex flex-col">
      <h4 class="text-2xl font-semibold text-slate-800">Schüler hinzufügen</h4>
      <UsersForm v-model="userData" role="student"></UsersForm>
      <div class="mt-5 flex flex-col gap-5">
        <DButton look="primary" class="mt-5" @click="onCreate">Schüler erstellen</DButton>
      </div>
    </div>
  </DModal>

  <DModal :open="open !== null" modal-class="sm:max-w-[500px]" @close="open = null">
    <div class="flex flex-col">
      <h4 class="text-2xl font-semibold text-slate-800">Schüler bearbeiten</h4>
      <UsersForm v-model="userData" role="student"></UsersForm>
      <div class="mt-2 grid grid-cols-2 gap-5">
        <DButton v-if="!userData?.deleted_at" look="danger-light" class="mt-5" @click="onDelete">Archivieren</DButton>
        <DButton look="primary" class="mt-5 w-full" @click="onSave">Speichern</DButton>
      </div>
    </div>
  </DModal>
</template>

<script lang="ts" setup>
import { useSWRVX } from '../../api/helper'
import supabase from '../../api/supabase'
import { Account } from '../../../../backend/test/types/index'
import { getOrganisationId } from '../../helper/general'
import UsersForm from '../../components/users/UsersForm.vue'
import DInput from '../../components/ui/DInput.vue'
import DButton from '../../components/ui/DButton.vue'
import DTable, { TableColumn } from '../../components/ui/DTable.vue'
import DPagination from '../../components/ui/DPagination.vue'
import DModal from '../../components/ui/DModal.vue'
import { computed, reactive, ref, watch } from 'vue'
import { mutate } from 'swrv'
import DToggle from '../../components/ui/DToggle.vue'
import { createModal } from '../../helper/Modal'
import { parseDateCalendar } from '../../helper/parseDate'
import * as yup from 'yup'
import { useForm } from 'vee-validate'
import yupLocaleDE from '../../locale/yupLocaleDE'

const state = reactive({
  search: '',
  showArchived: false,
})
const offset = ref(0)
const userData = ref({})

const tableColumns = [
  { name: 'Vorname', key: 'first_name' },
  { name: 'Nachname', key: 'last_name' },
  // { name: 'Rolle', key: 'role' },
  { name: 'Geburtstag', key: 'birthday' },
  { name: 'Klassenstufe', key: 'grade' },
] as TableColumn[]

const fetchAccountsQuery = computed(() => {
  let fetcher = supabase
    .from('accounts')
    .select('*', { count: 'exact' })
    .eq('organisation_id', getOrganisationId())
    .eq('role', 'student')
    .range(offset.value, offset.value + 10 - 1)
    .order('first_name')

  if (!state.showArchived) {
    fetcher = fetcher.is('deleted_at', null)
  } else {
    fetcher = fetcher.not('deleted_at', 'is', null)
  }

  if (state.search) {
    fetcher = fetcher.or(`first_name.ilike.%${state.search}%,last_name.ilike.%${state.search}%`)
  }

  return fetcher
})

const fetchAccounts = async () => {
  return fetchAccountsQuery.value?.then((res) => res)
}

const createAccount = (user: any) => {
  return supabase.from('accounts').insert({
    ...user,
    organisation_id: getOrganisationId(),
    role: 'student',
  }).select()
}

const updateAccount = (user: Account) => {
  return supabase
    .from('accounts')
    .update({
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      left_at: user.left_at,
      joined_at: user.joined_at,
      birthday: user.birthday,
      grade: user.grade,
    })
    .match({ id: user.id })
    .select()
}

const deleteAccount = async (user: any) => {
  await supabase.from('accounts').update({ left_at: new Date() }).match({ id: user.id })
  return supabase.from('accounts').delete().match({ id: user.id }).select()
}

const open = ref<string | null>(null)
const create = ref<boolean | null>(null)
const { data: users } = useSWRVX<{ data: Account[] }>(`/admin/students`, fetchAccounts)
const user = computed(() => {
  return users?.value?.data.find((el) => el.id === open.value)
    ? users?.value?.data.find((el) => el.id === open.value)
    : null
})

yup.setLocale(yupLocaleDE)
const schema = yup.object({
  first_name: yup.string().required().label('Vorname'),
  last_name: yup.string().required().label('Nachname'),
})
const { validate, resetForm } = useForm({
  validationSchema: schema,
  validateOnMount: false,
})

const onOpenCreate = () => {
  resetForm()
  create.value = true
}

const onOpen = (user: { id: string }) => {
  open.value = user.id
  userData.value = Object.assign({}, user)
}

const onSave = async () => {
  if (!(await validate())?.valid) return
  await updateAccount(userData.value as Account)
  open.value = null
  userData.value = {}

  mutate(`/admin/students`, fetchAccounts())
}
const onDelete = async () => {
  const confirmed = await createModal({
    confirm: 'Archivieren',
    cancel: 'Abbrechen',
    description: 'Möchten Sie den Schüler wirklich archivieren?',
    title: 'Schüler archivieren',
  })

  if (confirmed) {
    await deleteAccount(userData.value)
    open.value = null
    userData.value = {}

    mutate(`/admin/students`, fetchAccounts())
  }
}

const onCreate = async () => {
  if (!(await validate())?.valid) return
  await createAccount(userData.value)
  create.value = null
  userData.value = {}

  mutate(`/admin/students`, fetchAccounts())
}

watch(offset, (s) => {
  mutate(`/admin/students`, fetchAccounts())
})
watch(state, (s) => {
  offset.value = 0
  mutate(`/admin/students`, fetchAccounts())
})
</script>

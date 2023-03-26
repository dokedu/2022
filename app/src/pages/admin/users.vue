<template>
  <div>
    <div class="mb-3 text-xl font-medium">Nutzer</div>
    <div class="">
      <div class="flex flex-col">
        <div class="mb-5 flex">
          <DInput v-model="search" name="users_search" class="mr-5 w-full" placeholder="Nutzer suchen"></DInput>
          <DButton look="primary" @click="onOpenCreate"> Nutzer erstellen </DButton>
        </div>

        <DTable :items="users?.data || []" :columns="tableColumns" @open="onOpen">
          <template #role="{ column }">
            <span class="inline-flex rounded-full bg-slate-100 px-2 text-xs font-medium leading-5 text-slate-800">
              {{ translateRole(column) }}
            </span>
          </template>
        </DTable>

        <DPagination v-if="users?.count > 10" :limit="10" :offset="offset" :count="users?.count"
          @change="offset = $event"></DPagination>
      </div>
    </div>
  </div>

  <DModal :open="create" modal-class="sm:max-w-[500px] overflow-visible" @close="onClose">
    <UsersCreate @created="onCreated"></UsersCreate>
  </DModal>

  <DModal :open="open !== null" modal-class="sm:max-w-[500px] overflow-visible" @close="onClose">
    <div class="flex flex-col">
      <h4 class="text-2xl font-semibold text-slate-800">Nutzer bearbeiten</h4>
      <UsersForm v-model="userData"></UsersForm>
      <div class="mt-2 grid grid-cols-2 gap-5">
        <DButton look="danger-light" class="mt-5" @click="onDelete">Archivieren</DButton>
        <DButton look="primary" class="mt-5" @click="onSave">Speichern</DButton>
      </div>
    </div>
  </DModal>
</template>

<script lang="ts" setup>
import { useSWRVX } from '../../api/helper'
import supabase from '../../api/supabase'
import { getOrganisationId } from '../../utils/general'
import { computed, ref, watch } from 'vue'
import DInput from '../../components/DInput.vue'
import DButton from '../../components/DButton.vue'
import DTable, { TableColumn } from '../../components/DTable.vue'
import DPagination from '../../components/DPagination.vue'
import DModal from '../../components/DModal.vue'
import UsersForm from '../../components/d-users/UsersForm.vue'
import { mutate } from 'swrv'
import { createModal } from '../../utils/Modal'
import * as yup from 'yup'
import { useForm } from 'vee-validate'
import UsersCreate from '../../components/d-users/UsersCreate.vue'

const search = ref('')
const offset = ref(0)
const userData = ref({})

const tableColumns = [
  { name: 'Vorname', key: 'first_name' },
  { name: 'Nachname', key: 'last_name' },
  { name: 'Rolle', key: 'role' },
] as TableColumn[]

const accountsQuery = computed(() => {
  let fetcher = supabase
    .from('accounts')
    .select('*', { count: 'exact' })
    .eq('organisation_id', getOrganisationId())
    .neq('role', 'student')
    .not('identity_id', 'eq', '2UPUiv5T4t')
    .is('deleted_at', null)
    .range(offset.value, offset.value + 10 - 1)
    .order('first_name')

  if (search.value) {
    fetcher = fetcher.or(`first_name.ilike.%${search.value}%,last_name.ilike.%${search.value}%`)
  }

  return fetcher
})

const fetchAccounts = async () => {
  return accountsQuery.value.then((res) => res)
}

const updateAccount = (user: any) => {
  return supabase
    .from('accounts')
    .update({
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
    })
    .match({ id: user.id })
    .select()
}

const deleteAccount = (user: any) => {
  return supabase.from('accounts').delete().match({ id: user.id }).select()
}

const translateRole = (role: string) => {
  switch (role) {
    case 'owner':
      return 'Eigentümer'
    case 'admin':
      return 'Admin'
    case 'teacher':
      return 'Lehrer'
    case 'teacher_guest':
      return 'Gast-Lehrer'
    default:
      return role
  }
}

const open = ref<string | null>(null)
const create = ref<boolean | null>(false)

const onCreated = () => {
  create.value = false
  mutate(`/admin/users`, fetchAccounts())
}

const user = computed(() => {
  return users?.value?.data.find((el: any) => el.id === open.value)
    ? users?.value?.data.find((el: any) => el.id === open.value)
    : null
})

const onOpenCreate = () => {
  create.value = true
}

const onOpen = (user: { id: string }) => {
  open.value = user.id
  userData.value = Object.assign({}, user)
}

const onClose = () => {
  open.value = null
  create.value = false
  userData.value = {}
}

const schemaUpdate = yup.object({
  first_name: yup.string().required().label('Vorname'),
  last_name: yup.string().required().label('Nachname'),
  role: yup.string().required().nullable().label('Rolle'),
})
const { validate: validateSave } = useForm({
  validationSchema: schemaUpdate,
  validateOnMount: false,
})

const onSave = async () => {
  if (!(await validateSave())?.valid) return
  await updateAccount(userData.value)
  userData.value = {}
  open.value = null

  mutate(`/admin/users`, fetchAccounts())
}

const onDelete = async () => {
  const confirmed = await createModal({
    confirm: 'Archivieren',
    cancel: 'Abbrechen',
    description: 'Möchten Sie den Nutzer wirklich archivieren?',
    title: 'Nutzer archivieren',
  })

  if (confirmed) {
    await deleteAccount(userData.value)
    userData.value = {}
    open.value = null

    mutate(`/admin/users`, fetchAccounts())
  }
}

watch(offset, (s) => {
  mutate(`/admin/users`, fetchAccounts())
})

watch(search, (s) => {
  offset.value = 0
  mutate(`/admin/users`, fetchAccounts())
})

const { data: users }: any = useSWRVX(`/admin/users`, fetchAccounts)
</script>

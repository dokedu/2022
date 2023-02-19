<template>
  <div>
    <table>
      <tr>
        <th>ID</th>
        <th>Name</th>
        <th></th>
      </tr>
      <tr v-for="organisation in organisations" :key="organisation.id">
        <td>{{ organisation.id }}</td>
        <td>{{ organisation.name }}</td>
        <td><button @click="() => useOrg(organisation.id)">Use</button></td>
      </tr>
    </table>
  </div>
</template>

<script lang="ts" setup>
import { useStore } from '../../store/store'
import supabase from '../../api/supabase'
import { Account } from '../../../../backend/test/types'
import { router } from '../../router/_index'

const store = useStore()

const { organisations } = store

async function useOrg(id: string) {
  let org = organisations.find((a) => a.id === id)
  if (!org) {
    alert('org not found')
    return
  }

  store.organisationId = org.id
  localStorage.setItem('organisationId', store.organisationId)

  const { data: account, error } = await supabase
    .from<Account & { 'identities.user_id': string }>('accounts')
    .select('*,identities!inner (user_id)')
    .eq('organisation_id', store.organisationId)
    .eq('identities.user_id', store.user.id)
    .order('created_at')
    .single()

  if (error || account === null) return false

  store.account = account

  await router.push('/')
}
</script>

<style lang="css" scoped>
td {
  border: 1px solid;
}
</style>

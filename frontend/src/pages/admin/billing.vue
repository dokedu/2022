<template>
  <div>
    <div class="mb-3 text-xl font-medium">Abrechnung</div>
    <p class="text-gray-500">
      Du hast {{ users?.data.length }} Nutzer. Das entspricht
      {{ users?.data.length * 5 > 25 ? users?.data.length * 5 : 25 }} Euro / monatlich bei jährlicher Abrechnung. Also
      {{ users?.data.length * 5 > 25 ? users?.data.length * 5 * 12 : 25 * 12 }} Euro im Jahr.
    </p>
  </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import supabase from '../../api/supabase'
import { getOrganisationId } from '../../helper/general'
import { useSWRVX } from '../../api/helper'

const fetchAccountsQuery = computed(() => {
  let fetcher = supabase
    .from('accounts')
    .select('id', { count: 'exact' })
    .neq('role', 'student')
    .not('identity_id', 'eq', '2UPUiv5T4t')
    .is('deleted_at', null)
    .eq('organisation_id', getOrganisationId())

  return fetcher
})

const fetchAccounts = async () => {
  return fetchAccountsQuery.value?.then((res) => res)
}

const { data: users } = useSWRVX(`/admin/billing`, fetchAccounts)
</script>

import useSWRV from 'swrv'
import { nanoid } from 'nanoid'
import { createClient } from '@supabase/supabase-js'
import ApiClient from './apiClient'
import { computed } from 'vue'

const swrvFetchWrapper = async (promise: Promise<any>) => {
  const response = await promise

  if (response.error) throw response.error.message
  return response.data
}

export const useSWRVS = <T>(key: string | any, fetcher: any, options = {}) => {
  return useSWRV<T>(key, () => swrvFetchWrapper(fetcher), options)
}

// X wrapper
export const swrvFetchWrapperX = async <T>(response: any) => {
  if (response.error) throw response.error.message
  return { ...response, data: response.data as T }
}

export const useSWRVX = <T>(key: any | string, fetcher: any) => {
  const wrapped = computed(() => () => fetcher().then(swrvFetchWrapperX))
  return useSWRV<T>(key, wrapped.value)
}

export function getClient() {
  return new ApiClient(
    createClient(
      import.meta.env.VITE_SUPABASE_URL || 'http://localhost:8000',
      (import.meta.env.VITE_SUPABASE_ANON as string) || 'JWT', // TODO: add dev jwt
    ),
  )
}

export async function createTestUser() {
  const client = getClient()
  const email = `test.${nanoid()}@dokedu.email`

  const res = await client.auth.signUp({
    email,
    password: '12345678',
  })

  const initRes = await client.initAccount()

  const identity = await client.from('identities').select().eq('id', initRes.data.identity_id).single()

  return { supabase: client, user: res.user, identity: identity.data }
}
